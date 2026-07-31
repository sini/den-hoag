# TEMPORAL-KEY tripwire — no Nix source comment may key a reader to a TASK NUMBER.
#
# THE RULE. A comment cites a MECHANISM, a LAW, or a spec section; never a work item. A `(Task <n>)`
# key names a row in a plan document, and the plan closes while the code stays — so the moment the task
# is done the key points at something that no longer describes what it annotates, and a reader who
# chases it is reading a rotted reference. It is not even a stable coordinate: this tree carried three
# unrelated keys sharing one number, written by three different plans (the identity-law surface, the
# projection arg-env crossing hook, and the enrich→structural stratum map), so such a key cannot be
# resolved at all without first knowing which plan authored it.
#
# WHAT THIS MUST NOT CATCH. The repo's convention is to cite spec sections (`§2.10`, `spec §5 (b)`) and
# laws (`Law A15`), and those citations are the REPLACEMENT for a work-item key, not another instance
# of it: a spec section is versioned with the design it describes and stays resolvable. The scan's word
# set is the single word below, so no `§`-ref and no law id can reach it — the discrimination is
# structural, not a heuristic over neighbouring words. Both directions are pinned as tests, so a green
# `test-no-temporal-keys` is a measurement and not a predicate that could never have fired.
#
# THE DOMAIN IS NIX SOURCE. The two record documents that still carry such keys — the append-only
# parity deviation ledger and the frozen-pin corpus survey — are dated records of one plan's execution,
# and a record scoped to a plan may name that plan's rows: record and reference rot together, which is
# the property source comments lack. They are markdown, so the `.nix` domain excludes them without an
# exemption list to maintain.
#
# PHASE KEYS ARE DELIBERATELY OUT OF SCOPE. `Phase N` splits, and only one half is a temporal key.
# `Phase 5a`/`Phase 5b` are the productions substrate's CAPABILITY TIERS — REFERENCE.md heads a section
# with them and `concern-productions.nix` rejects a non-5a `mode` by that name at runtime — and den v1's
# `phases 1-3` are its own resolve pipeline's stages. Both are mechanisms, and forbidding them would
# delete real vocabulary. The other half, an implementation-sequence marker ("once Phase 5 wires the
# real edges"), IS a temporal key; those are corrected per-site against measured state, because several
# assert something FALSE about the tree and a word-sweep would keep the false claim while removing the
# label that flags it. Widening the word set is available once no sequence marker remains; doing it
# today would need a hand-listed exemption, which is what `_lib/core-files.nix` exists to argue against.
{
  denHoagSrc,
  nixpkgsLib,
  ...
}:
let
  inherit (nixpkgsLib) hasPrefix splitString;

  # The scan domain: every `.nix` file in the tree, DERIVED (`_lib/nix-source-files.nix`). A new file,
  # or a whole new directory, is scanned the moment it exists.
  sourceFiles = import ./_lib/nix-source-files.nix { inherit denHoagSrc nixpkgsLib; };

  digits = [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
  ];
  isDigit = c: builtins.elem c digits;

  # The three written cases of the word. Splitting on the WORD and inspecting what FOLLOWS is what keeps
  # this a plain string scan: the digit and separator dimensions never enter the token set, so there is
  # no large token product to run over every file, and no regex — `lib.hasInfix`'s `.*<tok>.*` form is
  # the one that overflows the matcher's stack on files this size.
  words = [
    "Task"
    "task"
    "TASK"
  ];

  # A plural `s` splits off with the following text, so it is stepped over before the separator test.
  afterPlural =
    seg:
    if hasPrefix "s" seg || hasPrefix "S" seg then
      builtins.substring 1 (builtins.stringLength seg) seg
    else
      seg;

  # A segment (the text FOLLOWING an occurrence of the word) opens a temporal key iff a digit follows
  # immediately, or follows a single space or hyphen. Catches the written forms `Task <n>`, `Task-<n>`,
  # `Task<n>` and `Tasks <n>`; a bare `Task` with no number is ordinary English and passes.
  opensKey =
    seg0:
    let
      seg = afterPlural seg0;
      c0 = builtins.substring 0 1 seg;
      c1 = builtins.substring 1 1 seg;
    in
    isDigit c0 || ((c0 == " " || c0 == "-") && isDigit c1);

  # Every temporal key in a text, as the reconstructed token. THE instrument — applied below to the tree
  # AND to both control texts, so all three verdicts come from one scanner in one run.
  keysIn =
    text:
    builtins.concatMap (
      w:
      map (seg: "${w}${builtins.substring 0 3 seg}") (
        builtins.filter opensKey (builtins.tail (splitString w text))
      )
    ) words;

  offenders = builtins.concatMap (
    f: map (k: "${f}:${k}") (keysIn (builtins.readFile "${denHoagSrc}/${f}"))
  ) sourceFiles;

  # The control texts are ASSEMBLED from the scanner's own word, never written as literals — this file
  # is inside its own scan domain, and a guard whose source violates its rule is a guard that has to
  # exempt itself. Assembly is also what a real comment does, so the fixture is call-site-producible.
  keyWord = builtins.head words;
  positiveText = "# THE ANCHOR (${keyWord} 7 subsume proof): reach = the node's own scope subtree.";
  conventionText = "# ROUTE CLASS-REMAP (spec §5 (b), Law A15, §2.10) over attributes 1–6, edges 3/4.";

  # Representative files from every root the walk must reach. A scan set that silently missed a
  # directory would report the same empty offender list as a clean tree.
  coverageProbes = [
    "default.nix"
    "lib/default.nix"
    "lib/attributes/output-modules.nix"
    "lib/compat/compile.nix"
    "lib/compat/legacy/forwards.nix"
    "ci/tests/boundary.nix"
    "ci/tests/_lib/core-files.nix"
    "parity/flake.nix"
    "parity/tests/scaffold.nix"
  ];
in
{
  flake.tests.temporal-keys = {
    # No Nix comment in the tree keys a reader to a task number. A failure names the file AND the token.
    test-no-temporal-keys = {
      expr = offenders;
      expected = [ ];
    };

    # POSITIVE CONTROL — the same scanner over a text that DOES carry a key must report it. Without
    # this, the empty offender list above could equally mean "the scan cannot match anything".
    test-scan-catches-a-key = {
      expr = keysIn positiveText;
      expected = [ "${keyWord} 7 " ];
    };

    # NEGATIVE CONTROL — the citation convention a key is REPLACED by must pass through untouched. This
    # is the guard's discriminating claim, stated as a test rather than as prose.
    test-scan-passes-the-citation-convention = {
      expr = keysIn conventionText;
      expected = [ ];
    };

    # The derived walk reaches every root: the repo top level, the kernel, the shim (including its
    # nested legacy directory), the suite, the suite's `_lib`, and the parity harness.
    test-scan-covers-every-tree-root = {
      expr = builtins.filter (f: !(builtins.elem f sourceFiles)) coverageProbes;
      expected = [ ];
    };
  };
}
