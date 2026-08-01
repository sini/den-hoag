# THE CLASS-SLICE CONSTRUCTION GUARD (spec §14.5, C7 stated as a check) — a `boundary.nix`-style lexical
# tripwire over `lib/` and `ci/`.
#
# WHAT IT GUARDS, and the statement is deliberately narrow. The unification's construction argument is that
# NO CONSUMER CAN TAKE A CLASS SLICE THAT HAS NOT PASSED THROUGH THE RELOCATION EQUATION. That is a property
# of what leaves `lib/attributes/class-modules.nix`: the relocation-aware `classSliceAt` is exported, the raw
# per-channel read is not, and the two field projections the extraction is built from are not. Those are
# lexical facts, so they get a lexical guard — and the behavioural half (that the exported entry point is
# threaded the RIGHT scope) is discharged by the projection suites, not here.
#
# WHAT IT CANNOT SEE, stated because this file invites the opposite reading: it sees that a name is absent
# and that a binding has the right arity, never that a call site passes the right VALUE. A `sourceOrderOf`
# threaded with an identity default satisfies every row below while answering as though no relocation
# existed; that residual is behavioural and lives in `ci/tests/projection.nix` and
# `ci/tests/projection-routes.nix`.
#
# EVERY ROW CARRIES A SAME-RUN POSITIVE CONTROL, because an absence claim from a predicate that could not
# have matched is the failure mode this project has already convicted. Where a row's own comparand is zero
# at HEAD, the control runs the SAME predicate over an input where it is nonzero.
#
# ★ THE MATCH IS A SUBSTRING MATCH, and the asymmetry it creates is stated rather than left for a reader to
# discover. On an ABSENCE row it over-reports — a longer identifier CONTAINING the forbidden token trips the
# row — which is the fail-closed direction and correct for a tripwire. On a COUNT row it under-detects a
# rename to a longer name containing the old one (`classSeedsAt` → `classSeedsAtSomething` holds the count),
# so the count rows guard the presence of the binding and not the exact spelling of its name. Measured: a
# rename AWAY from the token moves the count and fires; a rename that EXTENDS it does not.
{
  genPrelude,
  denHoagSrc,
  nixpkgsLib,
  ...
}:
let
  isNix = n: nixpkgsLib.hasSuffix ".nix" n;

  # THE SCAN SET IS DERIVED, for the reason `_lib/core-files.nix` states at length: a hand-written list of
  # files silently falls behind the tree, and a guard covering a shrinking fraction of it keeps reporting
  # success. Both roots are walked recursively, `lib/compat` included — the spec's predicate is stated over
  # `lib/` and `ci/` without exception, and the shim is exactly the consumer a leaked raw read would serve.
  walk =
    root: rel:
    let
      entries = builtins.readDir "${denHoagSrc}/${root}/${rel}";
    in
    builtins.concatMap (
      n:
      if entries.${n} == "directory" then
        walk root "${rel}${n}/"
      else if isNix n then
        [ "${root}/${rel}${n}" ]
      else
        [ ]
    ) (builtins.attrNames entries);

  # ★ THIS FILE EXCLUDES ITSELF, and the exclusion is asserted to be exactly one file. A lexical guard names
  # the tokens it forbids, so it necessarily contains every one of them; scanning itself would make each row
  # fail on its own statement. The exclusion is a NAMED SINGLETON rather than a pattern so a second file
  # cannot quietly claim it — `test-guard-self-exclusion-is-one-named-file` is that assertion.
  selfPath = "ci/tests/class-slice-guard.nix";
  scanned = builtins.filter (f: f != selfPath) (walk "lib" "" ++ walk "ci" "");

  linesOf = f: nixpkgsLib.splitString "\n" (builtins.readFile "${denHoagSrc}/${f}");
  # A CODE line is one whose first non-blank character is not `#`. The distinction is load-bearing for the
  # raw-read row: `rawSliceOf` is named in the prose of four other files (the emptiness rule's owner, its two
  # readers, and a test header), and a comment naming a private helper is documentation, not a consumer.
  # A trailing comment on a code line still counts — the direction that over-reports, which for a tripwire is
  # the safe one.
  isComment =
    l:
    let
      s = nixpkgsLib.removePrefix " " l;
    in
    nixpkgsLib.hasPrefix "#" (builtins.replaceStrings [ " " ] [ "" ] (builtins.substring 0 40 s));
  codeLinesOf = f: builtins.filter (l: !(isComment l)) (linesOf f);

  # every (file, line) pair in which `tok` appears, over the given line projection.
  hitsOf =
    proj: tok:
    builtins.concatMap (
      f: map (_: f) (builtins.filter (l: genPrelude.hasInfix tok l) (proj f))
    ) scanned;
  codeHits = hitsOf codeLinesOf;
  allHits = hitsOf linesOf;
  filesOf = hits: nixpkgsLib.unique hits;
  outside = file: hits: builtins.filter (f: f != file) hits;

  classModules = "lib/attributes/class-modules.nix";
  outputModules = "lib/attributes/output-modules.nix";

  # A file OWNS a token when it binds the name itself (`<tok> =` at any indent). The field-projection row
  # needs this because `lib/attributes/resolved-aspects.nix` binds a LOCAL `scopeOf = self.node nid` — a
  # different value of a different type, which a bare name-absence predicate would report as a violation and
  # a file-level exclusion would answer by not looking. Owning the name is the honest scoping: a file that
  # takes `class-modules`' projection instead (by call or by `inherit`) uses the token WITHOUT binding it,
  # which is exactly the leak IC-1's ruling forbids, and it still fires.
  bindsOwn = tok: f: builtins.any (l: genPrelude.hasInfix "${tok} =" l) (codeLinesOf f);
  leakedFiles =
    tok: builtins.filter (f: f != classModules && !(bindsOwn tok f)) (filesOf (codeHits tok));
  homonymFiles =
    tok: builtins.filter (f: f != classModules && bindsOwn tok f) (filesOf (codeHits tok));

  countIn = file: hits: builtins.length (builtins.filter (f: f == file) hits);

  # ── the two structural extractions, both anchored on the top-level binding's own indent ────────────────
  readSrc = f: builtins.readFile "${denHoagSrc}/${f}";
  formalsOf =
    file: name:
    let
      parts = nixpkgsLib.splitString "\n  ${name} =\n" (readSrc file);
    in
    if builtins.length parts != 2 then
      "<not a unique top-level binding: ${toString (builtins.length parts - 1)} matches>"
    else
      nixpkgsLib.trim (builtins.head (nixpkgsLib.splitString "\n" (builtins.elemAt parts 1)));

  exportSetOf =
    let
      afterBinding = builtins.elemAt (nixpkgsLib.splitString "mkClassSlice =" (readSrc "lib/attributes/default.nix")) 1;
      afterInherit = builtins.elemAt (nixpkgsLib.splitString "inherit (cm)" afterBinding) 1;
      body = builtins.head (nixpkgsLib.splitString ";" afterInherit);
    in
    builtins.filter (s: s != "") (
      nixpkgsLib.splitString " " (builtins.replaceStrings [ "\n" ] [ " " ] body)
    );
in
{
  flake.tests.class-slice-guard = {
    # ── the scan set itself, and its one exclusion ──────────────────────────────────────────────────────
    test-guard-self-exclusion-is-one-named-file = {
      expr = {
        excluded = builtins.filter (f: !(builtins.elem f scanned)) (walk "lib" "" ++ walk "ci" "");
        # NON-VACUITY: the scan set must actually reach both roots, or every absence row below is an
        # absence over nothing.
        reachesLib = builtins.elem classModules scanned;
        reachesCi = builtins.elem "ci/tests/projection-routes.nix" scanned;
      };
      expected = {
        excluded = [ selfPath ];
        reachesLib = true;
        reachesCi = true;
      };
    };

    # ── (1) NO EXPORTED RAW READ: the pre-unification name is gone entirely ─────────────────────────────
    # `classSliceOf` was the extraction that answered the UN-RELOCATED question, and the rename had to reach
    # every file naming it — including the comment-only ones, which is why this row counts ALL lines rather
    # than code lines. Its positive control is the name that replaced it, over the identical predicate and
    # the identical scan set: if the scan could not see `classSliceAt` it could not have seen `classSliceOf`
    # either, and the zero would mean nothing.
    test-guard-raw-extraction-name-absent = {
      expr = {
        raw = allHits "classSliceOf";
        controlReplacementPresent = builtins.length (filesOf (allHits "classSliceAt")) >= 4;
      };
      expected = {
        raw = [ ];
        controlReplacementPresent = true;
      };
    };

    # ── (2) THE RAW PER-ELEMENT READ IS CONFINED to the file that owns it ───────────────────────────────
    # This is the half of §14.5 that carries the C7 argument: `rawSliceOf` reads ONE channel, so a consumer
    # holding it could take a slice that never passed through the preimage. It is named in four other files'
    # PROSE, so the predicate is over code lines — and the control is that the comment-inclusive count over
    # the same files is nonzero, which is what proves the comment strip is doing work rather than the token
    # simply being absent.
    test-guard-raw-read-confined-to-owning-file = {
      expr = {
        codeOutside = outside classModules (codeHits "rawSliceOf");
        codeInside = countIn classModules (codeHits "rawSliceOf");
        controlProseOutsideIsNonzero = builtins.length (outside classModules (allHits "rawSliceOf")) > 0;
      };
      expected = {
        codeOutside = [ ]; # no consumer takes the raw read.
        codeInside = 2; # its definition and its single call, inside `classSliceAt`.
        controlProseOutsideIsNonzero = true; # the strip removed real matches.
      };
    };

    # ── (3) THE SECOND INJECTION PRODUCER IS GONE ───────────────────────────────────────────────────────
    # `rawSeedsAt` appended injected modules applying NONE of the raw read's five tests — an un-gated
    # producer beside the extraction, which is what made the reserved-channel refusals reachable by only one
    # of two paths. Removing it is part of the split's closure. Control: the same predicate on a token that
    # SURVIVES the same rewrite answers nonzero.
    test-guard-second-injection-producer-removed = {
      expr = {
        removed = codeHits "rawSeedsAt";
        controlSurvivingSiblingPresent = builtins.length (codeHits "classSeedsAt") > 0;
      };
      expected = {
        removed = [ ];
        controlSurvivingSiblingPresent = true;
      };
    };

    # ── (4) THE TWICE-BOUND NAME, SCOPED — a name-only guard here would be unsatisfiable ────────────────
    # `classSeedsAt` names two different things: the dying producer-side helper in `class-modules.nix`, and a
    # LIVE accessor in `output-modules.nix` (`id: result.get id "class-seeds"`) that `classSubtreeSeeds`
    # calls. So the row is stated per file — zero in one, exactly the surviving three lines in the other —
    # and the second half is itself the first half's positive control.
    test-guard-class-seeds-helper-scoped = {
      expr = {
        inClassModules = countIn classModules (allHits "classSeedsAt");
        inOutputModules = countIn outputModules (allHits "classSeedsAt");
      };
      expected = {
        inClassModules = 0; # the producer-side helper is gone.
        inOutputModules = 3; # the accessor, its comment, and its call — all must survive.
      };
    };

    # ── (5) THE FIELD PROJECTIONS STAY PRIVATE — the lexical form of IC-1's ruling ──────────────────────
    # `scopeOf` and `assertedOf` are one field read each with a named throw. Exporting either would publish
    # an accessor for a value the caller already holds, and — the concrete failure the ruling corrected — let
    # a caller re-derive the `assertedClasses` union outside the file that owns the projection.
    # THE HOMONYM IS ENUMERATED, NOT EXEMPTED BY FILE: `resolved-aspects.nix` binds its own local `scopeOf`,
    # so it owns the name; the row asserts that the set of files claiming that is exactly the one, which is
    # what stops a second homonym from arriving unremarked.
    # ★ ITS LIMIT, which is the shape of that same exemption: `bindsOwn` is FILE-wide, never binding-wide. A
    # file binding the token ANYWHERE leaves the leak set entirely, so `resolved-aspects.nix` is dark to
    # ITSELF for `scopeOf` — a genuine leak added to that file, taking `class-modules`' projection by call or
    # by `inherit`, is discarded beside the local binding that has nothing to do with it, and the row still
    # answers `[ ]`. What the row does see is the ARRIVAL of a shadow: a second file binding the name lands in
    # `scopeOfHomonyms` and fails the enumeration. So the homonym list is a tripwire on NEW owners and not a
    # check on a file already holding one, and the exempted file's own uses stay outside this row's reach for
    # exactly as long as its local `scopeOf` stands.
    test-guard-field-projections-stay-private = {
      expr = {
        scopeOfLeaks = leakedFiles "scopeOf";
        assertedOfLeaks = leakedFiles "assertedOf";
        scopeOfHomonyms = homonymFiles "scopeOf";
        assertedOfHomonyms = homonymFiles "assertedOf";
        # CONTROL: the same predicate on an EXPORTED name of the same file, which no other file binds, must
        # report the consumers — so a `[ ]` above is privacy and not a predicate that cannot match.
        controlExportedNameIsUsedElsewhere = builtins.length (leakedFiles "classSliceAt") > 0;
      };
      expected = {
        scopeOfLeaks = [ ];
        assertedOfLeaks = [ ];
        scopeOfHomonyms = [ "lib/attributes/resolved-aspects.nix" ];
        assertedOfHomonyms = [ ];
        controlExportedNameIsUsedElsewhere = true;
      };
    };

    # ── (6) THE UNION IS NOT RE-DERIVED ACROSS THE FILE BOUNDARY — finding F-A's ruling ─────────────────
    # A caller spelling `exempt // n.assertedClasses` re-derives, outside the owning file, a set that file
    # already computes — and it does so as a BARE FIELD READ, which row (5) cannot see because no accessor is
    # named. ★ ITS NON-VACUITY COMPARAND IS NOT THE TREE: the token already answers zero in
    # `output-modules.nix`, and claiming otherwise would be the false-nonvacuity this file exists to avoid.
    # What it is non-vacuous against is a candidate specification that wrote exactly that expression. The
    # control is therefore the only one available and it is stated as such: the same predicate over the file
    # that legitimately carries the field answers nonzero.
    # It does NOT generalize to `scope`: that field is a value the caller must place in the record it builds,
    # where a bare read of `assertedClasses` has one use — repeating work.
    # ★ ITS COVERAGE IS EXACTLY ONE FILE, BY CONSTRUCTION, and the title's talk of a file BOUNDARY should not
    # be read as a claim about the whole scan set. `countIn outputModules` keeps the hits whose file is
    # `output-modules.nix` and discards every other one the scan collected, so the forbidden expression
    # written BYTE-IDENTICALLY anywhere else under `lib/` or `ci/` passes untouched — in a new `lib/attributes`
    # consumer projecting the reach, or in `ci/tests/_lib/projection-harness.nix`, which keeps a replica of
    # the projection body and is scanned but never counted. This guards ONE consumer. A second projecting
    # consumer is unguarded until it is added to the comparand by hand.
    test-guard-asserted-classes-not-re-derived = {
      expr = {
        inOutputModules = countIn outputModules (codeHits "assertedClasses");
        controlOwningFileIsNonzero = countIn classModules (codeHits "assertedClasses") > 0;
      };
      expected = {
        inOutputModules = 0;
        controlOwningFileIsNonzero = true;
      };
    };

    # ── (7) THE FORWARD FOLD TAKES THE PROJECTING SCOPE — the lexical form of IC-2's ruling ─────────────
    # `forwardModulesFor` matches a spec's `intoClass` against a DESTINATION coordinate, which is read
    # through the projecting scope's relocation — so it needs that scope as a formal. The order is the one
    # its two `exempt`-bearing siblings already fix, which makes its last three arguments identical to
    # `routeRemapFor`'s whole argument list; that sibling is the row's positive control, over the same
    # extractor and the same file.
    # ★ ITS LIMIT: the row sees that the formal exists and where it sits, never that the call site passes the
    # right scope into it. That residual is behavioural and §14.7's rows are where it is discharged.
    test-guard-forward-fold-takes-projecting-scope = {
      expr = {
        forwardModulesFor = formalsOf outputModules "forwardModulesFor";
        controlSibling = formalsOf outputModules "routeRemapFor";
      };
      expected = {
        forwardModulesFor = "reach: exempt: id: class:";
        controlSibling = "exempt: id: class:";
      };
    };

    # ── (8) THE EXPORT SET IS CLOSED AND NAMED ──────────────────────────────────────────────────────────
    # Through an earlier revision this row read as "no exported extraction at all", which was satisfiable
    # only while every helper was private; `sourceOrderOf` is now a legitimate fourth export, because it
    # returns a list of channel NAMES and no content, so it cannot be used to read a slice at all. The
    # predicate is therefore the enumeration plus the ARITY, so a fifth export cannot arrive unremarked.
    test-guard-export-set-closed-at-four = {
      expr = {
        exports = exportSetOf;
        arity = builtins.length exportSetOf;
      };
      expected = {
        exports = [
          "classSliceAt"
          "sourceOrderOf"
          "assertKeysRegistered"
          "forwardSourceClassesOf"
        ];
        arity = 4;
      };
    };
  };
}
