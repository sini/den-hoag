# THE EXECUTABLE CORE of `papers/den-architecture/specs/2026-07-29-three-state-ci-gate.md`.
#
# Every prescriptive mechanism the spec names — the two leaf forms (§1), G1/G2/G3 (§3),
# suite-completeness (1)–(4) (§5) and the scaffold's leaf construction (§6b) — is DEFINED here and
# EXERCISED below on BOTH arms. Run: `nix-unit <path>/xfail-core.nix`.
#
# PRESCRIBED HOME: `ci/tests/_probes/xfail-core-probe.nix` — OUTSIDE every governed anchor root, and
# that is a correctness requirement rather than tidiness. The expectation lines below are
# binding-shaped (`pipeOps = [ … ];  recoverEmits = [ … ];`), so at revision 3's prescribed
# `ci/tests/_lib/` home this file would enter its OWN index: `sitesOf "pipeOps"` would return the
# probe alongside `lib/concern-policies.nix`, and `testG3SitesAreDefinitionsNotOccurrences` would go
# false — the harness's own expectation lines admitted as binding sites for kernel constructs.
# `_probes/` is excluded from §5(4) by the same `_`-prefix rule that excludes `_lib/` and `_fixtures/`.
#
# ★ REVISION 5 removed the per-arm shape of revision 4's fix: attribution is applied ONCE, ABOVE the arm
# dispatch, by `scaffoldLeafOf`, so no arm — present or future — can produce a leaf that bypasses it.
# §6b's fix is no longer a thing an arm has; it is a thing the scaffold is. That mechanism is unchanged
# here and is not in question.
#
# ★ REVISION 6 CHANGED THE EVIDENCE, NOT THE MECHANISM. Revision 5's starred property test asserted
# key-agnosticism with
#   `builtins.all (k: leaf ? k) (builtins.filter (k: out ? k) assertionKeys)`
# and `?` TAKES A LITERAL ATTR PATH — `out ? k` asks for an attribute NAMED `k`. The domain was `[ ]`,
# `all p [ ]` is true, and the clause held for an empty leaf: `den-hoag-gg8`'s vacuous-over-empty defect,
# in the file that names `gg8` at every one of its own vacuity probes. Replacing the predicate body with
# `false` left revision 5 at 72/72, exit 0 (M23). THAT FINDING STANDS.
#
# ★ NO SELF-COORDINATE APPEARS IN THIS FILE OR IN THE SPEC, AND THAT IS A RULE RATHER THAN A TIDY-UP.
# The sentence above read "the file that cites `gg8` at :783" for two revisions. It was correct at
# revision 5, whose core was 1009 lines and cited `gg8` exactly once, at 783. Revision 6 grew the file
# to 1175 lines and revision 7 to 1404; the citation moved to six sites and `:783` came to name an
# unrelated assertion line. BOTH revisions re-derived every mutation count and NEITHER re-derived this
# coordinate — §12's rule "the baseline moved, so no count was carried" was applied to numbers and not
# to coordinates. A coordinate into an artefact that grows on every revision has to be re-derived on
# every revision; the construction in which that cannot go stale does not carry one. Coordinates into
# the den-hoag tree stay, because that tree is named at a rev; coordinates into revision 5's frozen
# artefacts stay, because frozen artefacts cannot move.
#
# ★★★ REVISION 7 WITHDRAWS THE SENTENCE REVISION 6 BUILT ON TOP OF IT. Revision 6 wrote that NO
# assertion at a single key list could have separated the projection from a per-arm rebuild, and on that
# ground re-typed revision 5's defect from UNWITNESSED to UNSATISFIABLE. The ground was an equivocation
# on the phrase "a per-arm rebuild":
#   • F37's object enumerates ALL SIX keys under one `out ? k` guard. That computes `out ∩ assertionKeys`
#     — it is the projection spelled longhand, and of course it agrees on every input. F37's table is
#     TRUE AND VACUOUS.
#   • the object the argument is about, and the one M21 builds, is the PER-ARM rebuild: each arm
#     enumerates the keys ITS OWN FORM declares. It DISAGREES with the projection at today's key list on
#     any `out` carrying a key the other form owns. One assertion, no scheme, no extension:
#       `attrNames (denTestLeaf { expr; expectedError; correct = 3; bead; construct; })`
#     → shipped `[ bead construct correct expectedError expr ]`; the per-arm rebuild drops `correct`.
#     Measured on nix-unit 2.34.2: shipped + that assertion → 77/77 exit 0, M21 + it → exit 1.
# ⇒ REVISION 5's CLAIM WAS UNWITNESSED, NOT UNSATISFIABLE, AND ONE ASSERTION WOULD HAVE DISCHARGED IT.
#
# ★★ AND THIS FILE'S OWN FIXTURE DERIVATION IS WHAT HID IT. `formExclusive.error` excluded `correct` on
# the stated ground that "the scaffold refuses it by name" — TRUE of `expected`, FALSE of `correct`,
# which nothing refuses and which censuses cleanly end to end. The exclusion removed THE ONE INPUT SHAPE
# at which the two constructions disagree, from the fixture whose derivation was supposed to make it
# general. The exclusion is now exactly the refusal set, and the error arm's projection test separates
# the per-arm rebuild at TODAY's list.
#
# ★ THE SCHEME SURVIVES AND IS STILL THE RIGHT FORMULATION — it is COMPLEMENTARY to that assertion, not
# a substitute for it. Two different properties were riding on revision 5's one sentence, and revision 6
# collapsed them: FORM-INDEPENDENCE (reachable at one key list) and NATURALITY IN THE KEY SET (reachable
# only by applying the scheme at a second list). `scaffoldLeafOfBy` takes the key list, the shipped pair
# is its single application, and M21 now kills BOTH tests, one per property (of six rows in all).
# Revision 6's error was in
# the licence it wrote for the scheme, not in the scheme. Its DOMAIN is now declared (`formKeys ⊆ keys`)
# rather than left as an uncaught missing-attribute EvalError at a list it was never applied to.
#
# ★ `denHoagSrc` is a STRING, not a path literal. Revision 3 wrote `denHoagSrc = /home/…/den-hoag`, so
# `"${denHoagSrc}/lib"` COERCED the path and copied the whole repository — `.git` included — into the
# store on every cold run. In the shipped form the value arrives from `ci/flake.nix`'s existing
# `denHoagSrc = "${inputs.den-hoag}"` specialArg, which is already a store-path STRING; the probe
# matches that type so the probe's cost is the shipped cost.
let
  denHoagSrc = "/home/sini/Documents/repos/sini/den-hoag";

  # ── prelude (genPrelude.hasInfix's shape: splitString, never a `.*needle.*` regex over a whole
  #    file — the nixpkgs form overflows the C stack on whole-file input, as ci.yml records). ──────
  escapeRE =
    s:
    builtins.replaceStrings [ "." "*" "+" "?" "[" "]" "(" ")" "^" "$" "\\" "|" "{" "}" ] [
      "\\." "\\*" "\\+" "\\?" "\\[" "\\]" "\\(" "\\)" "\\^" "\\$" "\\\\" "\\|" "\\{" "\\}"
    ] s;
  splitOn = sep: s: builtins.filter builtins.isString (builtins.split (escapeRE sep) s);
  hasInfix = needle: hay: builtins.length (splitOn needle hay) > 1;
  elem = builtins.elem;
  uniqSort =
    xs: builtins.sort (a: b: a < b) (builtins.attrNames (builtins.listToAttrs (map (x: { name = x; value = 1; }) xs)));
  countOcc = needle: s: builtins.length (splitOn needle s) - 1;

  # ═══ §3 G1 — bead SHAPE. `builtins.match` is a FULL match, so the pattern is anchored by
  #     construction. It rejects prose placeholders; it does NOT reject a well-formed id that does
  #     not exist — that check is out of eval (§10).
  beadShapeOk = b: builtins.isString b && builtins.match "den-hoag-[0-9a-z]{3}(\\.[0-9]+)*" b != null;

  # ═══ §1 the `msg` floor, AS A PREDICATE — so the census can re-check it. ══════════════════════
  # nix-unit's `msg` is a REGEX matched with SEARCH semantics. A pattern matches EVERY message iff it
  # can match the empty substring, which every string contains — i.e. iff `match msg "" != null`.
  # That is an exact characterisation, not a heuristic. It does NOT reject `"."`; that is stated, not
  # claimed away, and `"."` is what the census row EXHIBITS (it cannot check it).
  msgIsTotal = m: builtins.match m "" != null;

  # ═══ §3 G3 — the anchor index, DERIVED FROM SOURCE. ═══════════════════════════════════════════
  #
  # `construct` is not tested for OCCURRENCE in file text (which admits comments and prose, and
  # survives the retirement it is supposed to witness). It is tested for MEMBERSHIP in the set of
  # identifiers BOUND by the governed source.
  #
  # ★ THE EXTRACTOR IS NOT A NIX LEXER AND THIS FILE DOES NOT PRETEND OTHERWISE. It is a per-line
  # `builtins.match` carrying exactly ONE bit of lexical state: whether the line sits inside an
  # indented (`''`) string. That bit is what revision 3 lacked, and its absence put 14 names into the
  # index that are bound NOWHERE — they are v1 configuration examples inside `''` usage documentation
  # (`lib/compat/batteries.nix`), a flake-parts error message (`lib/compat/flake-outputs.nix`) and a
  # shell variable in a `writeShellApplication` body (`lib/compat/nh.nix`). All 14 are asserted absent
  # below, with the r3 extractor asserted to admit them IN THE SAME RUN.
  #
  # Two escape forms must be removed BEFORE the `''` delimiters are counted, or the bit inverts and
  # stays inverted for the rest of the file:
  #   `''${`  — an escaped interpolation. `lib/compat/nh.nix:46` is `action="''${1:-…}"`, one `''`
  #             on a line INSIDE a string: counting it closes the string 3 lines early, and the
  #             file's real `let` bindings from line 62 on are then read as string content.
  #   `'''`   — an escaped `''`.
  # A `#`-comment tail is stripped before counting (but NOT before matching: a `#` line cannot
  # produce a binding anyway, since `#` is not in the identifier class), so a `''` MENTIONED in a
  # comment cannot flip the bit. ★ THAT STRIP IS ALSO A KNOWN LIMIT: on a line that OPENS AND CLOSES
  # a `''` string and then carries a `#`, the strip deletes the closing delimiter and the bit inverts
  # and stays inverted. Zero instances in the governed roots, measured with a same-run positive
  # control; pinned below at `testG3OneLineDocStringWithHashInvertsBit` and recorded at UNCOVERED-7.
  #
  # ★ `/* */` IS DELIBERATELY NOT TRACKED. The ground is that there are ZERO block comments in the
  # governed roots to track — all 17 `/*` occurrences are glob text inside `#` comments
  # (`modules/**.nix`, `legacy/*`, `den-behavioral/*`, `lib/**`) — so a tracker has nothing to find.
  # It is ALSO measurably worse in its naive form: a tracker that tests for `/*` BEFORE stripping the
  # `#` tail reads `ci/tests/_lib/den-compat-test.nix:9` as an opener, swallows the remaining 276
  # lines of that 285-line file, and loses 417 names including `denTest` — the harness root's own
  # control. A tracker that strips the `#` tail first loses NOTHING (0 names) and gains nothing.
  # Both figures are measured; the spec's F29 states the variant each belongs to.
  bindingPat = "[[:space:]]*([a-zA-Z_][a-zA-Z0-9_'.-]*)[[:space:]]*=([^=].*|)"; # `=` not `==`
  linesOf = t: builtins.filter builtins.isString (builtins.split "\n" t);
  namesOfLine =
    l:
    let m = builtins.match bindingPat l; in
    if m == null then
      [ ]
    else
      let
        p = builtins.head m;
        comps = builtins.filter builtins.isString (builtins.split "\\." p);
      in
      if builtins.length comps <= 1 then [ p ] else [ p (builtins.elemAt comps (builtins.length comps - 1)) ];

  stripHashTail = l: let m = builtins.match "([^#]*)#.*" l; in if m == null then l else builtins.head m;
  deEscape = s: builtins.replaceStrings [ "''\${" "'''" ] [ "" "" ] s;
  odd = n: builtins.bitAnd n 1 == 1;
  stepLine =
    st: l:
    if st.inStr then
      # inside a `''` string: contribute NOTHING, and close on an odd delimiter count.
      (if odd (countOcc "''" (deEscape l)) then st // { inStr = false; } else st)
    else
      { inStr = odd (countOcc "''" (deEscape (stripHashTail l))); out = st.out ++ namesOfLine l; };
  namesIn = t: (builtins.foldl' stepLine { inStr = false; out = [ ]; } (linesOf t)).out;

  # the REPLACED mechanism, retained so its failure is asserted beside the replacement's success.
  namesInLineLocal = t: builtins.concatMap namesOfLine (linesOf t);

  isNix = n: builtins.match ".*\\.nix" n != null;

  # THE GOVERNED ROOTS, enumerated. `construct` = "the binding whose deletion makes this claim
  # false". For a claim about the fleet that binding is in lib/; for a claim about the harness it
  # is in the harness — which is why `ci/tests/_lib` is a root and not an exception.
  anchorRoots = [
    { name = "core"; dir = "lib"; prefix = "lib/"; skipDirs = [ "compat" ]; }
    { name = "compat"; dir = "lib/compat"; prefix = "lib/compat/"; skipDirs = [ ]; }
    { name = "harness"; dir = "ci/tests/_lib"; prefix = "ci/tests/_lib/"; skipDirs = [ ]; }
  ];
  filesOfRoot =
    r:
    let
      base = "${denHoagSrc}/${r.dir}";
      walk =
        rel:
        let e = builtins.readDir "${base}/${rel}"; in
        builtins.concatMap (
          n:
          if e.${n} == "directory" then
            (if elem n r.skipDirs then [ ] else walk "${rel}${n}/")
          else if isNix n then
            [ "${rel}${n}" ]
          else
            [ ]
        ) (builtins.attrNames e);
    in
    walk "";

  # ★ THE HAYSTACK CONTROL, and it is a PROJECTION OF THE INDEX'S OWN FILE LIST rather than a second
  # walk. Revision 3's three per-root controls each named one binding at the TOP LEVEL of its root,
  # so they saw a root FULLY unreached and nothing finer: making the walk non-recursive removed 22
  # files and 20.7 % of the name-pairs with all three controls still green. A control derived from a
  # SEPARATE traversal would have the same defect for the same reason — it would be sound for a
  # different proposition than the one it is asked to prove. `contributingDirs` cannot: it is
  # `filesOfRoot` itself, mapped to directories, so a walk that stops descending loses the
  # directories from the very list the index is built from.
  dirOfRel =
    f:
    let comps = builtins.filter builtins.isString (builtins.split "/" f); in
    if builtins.length comps <= 1 then
      ""
    else
      builtins.concatStringsSep "/" (builtins.genList (i: builtins.elemAt comps i) (builtins.length comps - 1)) + "/";
  contributingDirs = r: uniqSort (map dirOfRel (filesOfRoot r));

  pairsOfRoot =
    r:
    builtins.concatMap (
      f: map (n: { name = n; file = "${r.prefix}${f}"; }) (namesIn (builtins.readFile "${denHoagSrc}/${r.dir}/${f}"))
    ) (filesOfRoot r);
  anchorPairs = builtins.concatMap pairsOfRoot anchorRoots;
  # name → the files that BIND it. Not a boolean: a partial retirement (one of N definitions
  # deleted) changes `sites` while membership survives, and the G2 census then goes red.
  sitesOf = n: uniqSort (map (p: p.file) (builtins.filter (p: p.name == n) anchorPairs));
  anchorResolves = c: builtins.isString c && sitesOf c != [ ];

  # ═══ §1 — the two leaf forms, WITH G1 AND G3 APPLIED BY THE CONSTRUCTOR. ══════════════════════
  #
  # ★★ There is no path from an author's keystrokes to a declared leaf that does not pass through
  # `checkedAttribution`: it is not a guard leaf someone remembers to write, it is the first thing
  # every producer forces. `builtins.seq` is load-bearing, and its property is now COVERED
  # (`testSeqDiagnosesAttributionFirst*`): without it the form-specific clause is the `if` condition
  # and therefore always evaluates first, so a leaf with BOTH a malformed bead and a total `msg`
  # reports the `msg`. The order is LEXICALLY FIXED either way — `seq` is what fixes it to
  # attribution-first, the diagnosis an author needs; it is not that the order becomes
  # caller-dependent without it.
  checkedAttribution =
    form: bead: construct:
    if !(beadShapeOk bead) then
      throw "xfail.${form}: `bead` is not a den-hoag tracker id — G1 rejects it. A declaration whose bead does not match `den-hoag-[0-9a-z]{3}(.N)*` attributes the known-fail to nothing"
    else if !(anchorResolves construct) then
      throw "xfail.${form}: `construct` is not bound in the governed source — G3 rejects it. `construct` must be an identifier the kernel BINDS, so that retiring it invalidates this declaration; a prose phrase or a comment cannot name a binding"
    else
      { inherit bead construct; };

  xfail = rec {
    xfailError =
      {
        bead,
        construct,
        expr,
        type,
        msg,
      }:
      let att = checkedAttribution "error" bead construct; in
      builtins.seq att (
        if msgIsTotal msg then
          throw "xfail.error: `msg` matches EVERY message (it matches the empty string, and nix-unit matches `msg` as a search) — such a pattern asserts nothing about the failure"
        else
          att // { inherit expr; expectedError = { inherit type msg; }; }
      );

    # ★ `correct` RIDES ON THE LEAF. Revision 4 discarded it after the degenerate check, which left
    # the leaf carrying a projection of the declaration rather than the declaration: `expected` alone
    # cannot say whether the claim is degenerate, so the census could not re-check the one clause
    # `expected` is derived from. F14d measures that nix-unit tolerates the extra key (re-measured:
    # a leaf carrying `correct` is ✅ with a same-run control), so the leaf carries the WHOLE claim
    # and the census re-checks all of it.
    xfailValue =
      {
        bead,
        construct,
        expr,
        actual,
        correct,
      }:
      let att = checkedAttribution "value" bead construct; in
      builtins.seq att (
        if actual == correct then
          throw "xfail.value: `actual` equals `correct` — a degenerate xfail claims today's value is also the right one"
        else
          att // { inherit expr correct; expected = actual; }
      );

    error = xfailError;
    value = xfailValue;

    # ★★★ §6b — THE ONE DEFINITION. `assertionKeys` partitions `out` EXACTLY: the leaf is `out`
    # projected onto it, and the flake-parts module face is the complement. Both uses are DERIVED
    # from this list, which is what "one definition, two uses" has claimed since revision 2 without
    # being true of any revision until this one.
    #
    # ★★★ AND THE PARTITION IS A SCHEME IN THE KEY LIST, NOT A BODY THAT MENTIONS ONE. Revision 5
    # wrote `intersectAttrs assertionKeySet out` with `assertionKeys` free, and then asserted
    # key-agnosticism by inspecting ONE fixture under ONE key list. TWO DIFFERENT PROPERTIES WERE
    # RIDING ON THAT ONE SENTENCE, and revision 6 collapsed them into one:
    #   • FORM-INDEPENDENCE — the carried set is a function of the key list and `out`, NEVER of which
    #     arm ran. A per-arm rebuild fails this AT TODAY'S LIST, on any `out` carrying a key the other
    #     form owns, and `testScaffoldErrorLeafIsTheProjectionOfOut` separates it now that the fixture
    #     no longer excludes `correct`. ★ F37 does NOT bear on this property: its rebuild enumerates
    #     all six keys under one `out ? k` guard, which is this projection written longhand.
    #   • NATURALITY IN THE KEY SET — the same construction at a DIFFERENT list. No assertion at one
    #     list reaches this one, which is why the list is an ARGUMENT and
    #     `testScaffoldExtendsToANewAssertionKey` APPLIES the scheme at a second list.
    # The two are complementary, and M21 kills one test per property.
    assertionKeys = [ "bead" "construct" "correct" "expected" "expectedError" "expr" ];
    setOf = ks: builtins.listToAttrs (map (k: { name = k; value = null; }) ks);
    assertionKeySet = setOf assertionKeys;
    # ── the two DECLARED sub-lists of `assertionKeys`, and they are declared for opposite reasons.
    # ⊂ assertionKeys. The attribution pair is ONE decision, not two — so `attributionOf` quantifies
    # over the list rather than reading two hand-written booleans, and "all of it or none of it" is
    # the shape of the check rather than a coincidence of how it was written.
    attributionKeys = [ "bead" "construct" ];
    # ⊂ assertionKeys. The DISPATCH pair — the two keys the scaffold names to decide WHICH FORM a leaf
    # is, as opposed to the keys it CARRIES (that number is bounded by the number of forms, F14c). It
    # is also the scheme's DOMAIN: `scaffoldLeafOfBy` reads these two off the projected leaf, so a
    # `keys` that omits either makes the dispatch read an attribute the projection cannot have carried.
    formKeys = [ "expected" "expectedError" ];

    # ★★★ THE LEAF IS A PROJECTION OF `out`, NOT A REBUILD OF IT.
    #
    # The shipped scaffold (`ci/tests/_lib/den-compat-test.nix:265-283`) is a single `if` whose
    # BOTH arms construct a fresh literal attrset from a fixed key set, so each silently drops every
    # field it does not name. The two known losses are ONE defect seen twice:
    #   • the ERROR arm returns `{ expr = (tryEval …).success; expected = false; }` — `expectedError`
    #     is ERASED, so `type` and `msg` never reach nix-unit. That is `den-hoag-6p9`, P0 BLOCKING.
    #   • the VALUE arm returns `{ expr; expected; }` (or the `intersectAttrs` variant) — `bead` and
    #     `construct` are ERASED, so a declared xfail censuses as `[ ]` and reports GREEN. All six of
    #     §6's declarations are value-form.
    # Revision 4 patched the first as a symptom (a bespoke leaf-shaping `errorLeafOf`) and left the
    # second live. A per-arm fix — even applied to both arms — reproduces the shape the next time a
    # field is added, because each arm would still be a list of fields to remember.
    #
    # The construction in which a field CANNOT be lost does not enumerate what to keep. The leaf is
    # `out ∩ assertionKeys`, and no arm builds it: the error arm reshapes NOTHING (the native channel
    # takes `expectedError` as authored — which is the whole of `6p9`'s fix), and the value arm's
    # only transformation is the v1 partial match, written as an override of the single key it
    # changes. A key added to `assertionKeys` later rides through both arms with no edit anywhere,
    # because no arm names any key.
    #
    # `attributionOf` is therefore a pure GUARD rather than a producer: the data is already on the
    # leaf by projection, so the check does not have to reconstruct it — and that coupling, check
    # with construction, is exactly what let revision 4's fix be arm-shaped in the first place.
    #
    # ★ IT QUANTIFIES OVER `attributionKeys` RATHER THAN READING TWO BOOLEANS. "Attribution is one
    # decision, not two" is then the SHAPE of the check — all of the list or none of it — rather than a
    # property of how two `?`s happened to be combined. Revision 6 declared `attributionKeys` and then
    # used it nowhere, while §6b's prose called it "the checked pair"; it is checked now.
    attributionOf =
      leaf:
      let
        present = builtins.filter (k: builtins.hasAttr k leaf) attributionKeys;
      in
      if builtins.length present == builtins.length attributionKeys then
        checkedAttribution "scaffold" leaf.bead leaf.construct
      else if present != [ ] then
        throw "xfail.scaffold: attribution is PARTIAL — `bead` and `construct` are one decision, not two. A leaf carrying one without the other becomes a census row with a missing field"
      else
        { };
    #
    # ★ THE ARM DISPATCH DOES NAME TWO KEYS, AND THAT IS A DIFFERENT ACT FROM CARRYING ONE.
    # `expectedError` and `expected` are what the two forms ARE — the discriminator, not a field
    # list. Naming a key to DECIDE WHICH FORM THIS IS is bounded by the number of forms (two, F14c);
    # naming a key to CARRY IT is bounded by nothing, and is the act that lost `bead` on revision 4.
    # A key added to `assertionKeys` changes neither dispatch nor carriage, which is the property
    # `testScaffoldExtendsToANewAssertionKey` applies rather than asserts.
    # ★★ THE SCHEME'S DOMAIN IS DECLARED, AT BOTH ARGUMENTS. Revision 6 asserted naturality "whatever
    # the list says" — a universal over key LISTS — and applied the scheme at exactly two, both
    # ⊇ assertionKeys. At a shorter list the dispatch reads `leaf.expected` off a leaf the projection
    # could not have carried it onto: a missing-attribute EvalError, which `tryEval` cannot see (F13)
    # and which surfaces as exactly the "☢️ with the throw escaping" this function converts to a named
    # refusal one line below. The same partiality sits at the OTHER argument — an `out` declaring
    # neither form key. Both are now named refusals. Absence is a decision at a scheme's own arguments
    # too, and a universal asserted at two instances does not get to leave its domain undeclared.
    scaffoldLeafOfBy =
      keys: out:
      if !(builtins.all (k: elem k keys) formKeys) then
        throw "xfail.scaffold: the key list omits a FORM key — `expected` and `expectedError` are what the dispatch reads to decide which form a leaf is, so the scheme is defined only for a `keys` containing both. A shorter list makes the dispatch read an attribute the projection cannot have carried"
      else
        let
          leaf = builtins.intersectAttrs (setOf keys) out;
          att = attributionOf leaf;
        in
        builtins.seq att (
          if leaf ? expectedError then
            # F14c, AS CORRECTED: a leaf carrying BOTH keys is ☢️ *when `expr` throws*, and ✅ GREEN
            # WITH `expectedError` SILENTLY IGNORED when it does not — nix-unit runs it as a value-form
            # test either way, and only the throwing case is loud. So this refusal covers TWO outcomes,
            # and the quiet one is the dangerous one. Revision 4's rebuild dropped `expected` here
            # SILENTLY; a projection cannot, so the authoring error is refused by name instead of
            # surfacing as an unexplained ☢️ — or as nothing at all.
            (
              if leaf ? expected then
                throw "xfail.scaffold: the leaf declares BOTH `expected` and `expectedError` — the two forms are disjoint, and nix-unit reports such a leaf as ☢️ with the throw escaping uncaught"
              else
                leaf
            )
          # ...and the fourth case of the same dispatch, which revision 6 left as an EvalError.
          else if !(leaf ? expected) then
            throw "xfail.scaffold: the leaf declares NEITHER `expected` nor `expectedError` — a leaf with no assertion form is not a test, and reading the absent key is an EvalError `tryEval` cannot catch"
          # PARTIAL MATCHING (denTest.nix:20-24): compare only the keys `expected` names when both are
          # attrsets. THE ONLY TRANSFORMATION THE SCAFFOLD PERFORMS, as an override of one key.
          else if builtins.isAttrs leaf.expected && builtins.isAttrs leaf.expr then
            leaf // { expr = builtins.intersectAttrs leaf.expected leaf.expr; }
          else
            leaf
        );
    # the COMPLEMENT of the same partition — what `fleetModule` hands to flake-parts today
    # (`removeAttrs … [ "expr" "expected" "expectedError" ]`, three keys, now derived from the six).
    fleetPartOfBy = keys: out: builtins.removeAttrs out keys;
    # ★ THE SHIPPED PAIR IS THE SCHEME APPLIED AT THE SHIPPED LIST — one application, written once,
    #   so the two faces cannot be specialised at different lists. This is the whole of what
    #   `ci/tests/_lib/xfail.nix` exports for the scaffold's use.
    scaffoldLeafOf = scaffoldLeafOfBy assertionKeys;
    fleetPartOf = fleetPartOfBy assertionKeys;
  };

  # the shipped scaffold's tail (`den-compat-test.nix:262-283`, twenty-two lines) is now this, and
  # nothing else.
  # ★★ TWO EXTENTS, ONE OBJECT — RESOLVED BY NAMING TWO OBJECTS, WHICH IS WHAT THEY ALWAYS WERE.
  # Revision 7 wrote `264-283`; revision 8 recorded the inconsistency and left `262-283` and `265-283`
  # both in circulation for one object. Re-read at den-hoag `0716eec`: 262 binds `expr`, 263 binds
  # `hasExpectedError`, 264 is `in`, 265 opens `if hasExpectedError then`, 283 closes the value arm.
  #   • `262-283` = WHAT THE REPLACEMENT DELETES — the two bindings lose their only reader when the
  #     dispatch goes, so they are part of the replaced text. This is the extent to cite for the fix.
  #   • `265-283` = THE DISPATCH ITSELF, which is what `denTestLeaf` reproduces verbatim below.
  # `264-283` names neither and is withdrawn. Both surviving extents are correct OF THEIR OWN OBJECT;
  # the defect was using them interchangeably, and it is fixed by saying which object is meant at each
  # site rather than by picking one number.
  denTestLeaf = out: xfail.scaffoldLeafOf out;

  # ═══ §3 G2 — the census, and THE SECOND ENFORCEMENT POINT. ════════════════════════════════════
  #
  # `censusOf` walks `attrNames` and selects leaves carrying `bead`. Because that selection IS the
  # definition of "a declared xfail", checking here makes the guards total over the tree: a leaf
  # written by hand, never touching a constructor, is still a census row and is still checked. The
  # constructor makes the bad leaf unbuildable on the sanctioned path; the census makes it
  # unreachable on every path. Neither alone is total, and revision 3 had neither.
  #
  # ★★★ WHAT THE CENSUS RE-CHECKS, EXACTLY — THE ENUMERATION IS PRINTED, NOT PERFORMED.
  #
  # The enumeration source is the CONSTRUCTOR TEXT above, not §1's prose bullet list, because that list
  # was measured lossy: it has five bullets, the census enumerated from it, and `expr` — required by both
  # destructuring patterns — is in neither. A by-construction clause is exactly one of three things, and
  # each is readable off the code rather than off a description of it:
  #   (i)   a field name in a constructor's destructuring pattern  → a required-ness clause;
  #   (ii)  an `if … then throw` in a constructor or in `checkedAttribution` → a value clause;
  #   (iii) a key a non-`...` pattern REFUSES → a disjointness clause.
  # Applied to `checkedAttribution` (2 ifs), `xfailError` ({ bead, construct, expr, type, msg } + 1 if)
  # and `xfailValue` ({ bead, construct, expr, actual, correct } + 1 if), that yields NINE leaf-level
  # properties. Every one is checked below; the census clause is named beside it:
  #    1  `bead` full-matches G1 ............... `beadShapeOk l.bead`
  #    2  `construct` resolves (G3) ............ `anchorResolves l.construct`
  #    3  the leaf carries `bead` .............. `!(l ? bead)`
  #    4  the leaf carries `construct` ......... `!(l ? construct)`
  #    5  the leaf carries `expr` .............. `!(l ? expr)`                      ★ new
  #    6  error form: `type` and `msg` present . `!(l.expectedError ? type) || !(… ? msg)`
  #    7  error form: `msg` is not total ....... `msgIsTotal l.expectedError.msg`
  #    8  value form: `expected`, `correct` .... `!(l ? expected)` ★ new, `!(l ? correct)`
  #    9  the forms are DISJOINT ............... `l ? expectedError && (l ? expected || l ? correct)` ★ new
  #   Revision 4 re-checked 1 and 2 only; revision 8 reached six of the nine; rows 5, 8's first half and
  #   9 are this revision's. The floor and the degenerate clause are re-checkable at all because both are
  #   predicates on keys the leaf carries — which is why `correct` rides on the leaf.
  # ★ THE ENUMERATION IS PRINTED SO A REVIEWER CAN DIFF THE SOURCE AGAINST THE LIST rather than trust
  #   that the author walked it. Revision 8 named its class correctly, named its enumeration source
  #   correctly, and dropped a member of that source in the walk — and that is invisible from inside,
  #   because the author performed the sweep and can point at it. A stated method is not a performed one.
  # ★ WHAT IT DOES NOT CHECK, and cannot: that the bead EXISTS and is OPEN (out of eval, §10), and
  #   that `expr` actually produces `expected` (that is nix-unit's job, and it is what makes the
  #   three verdicts work). `msg = "."` is EXHIBITED in the row, not checked — F25's equivalence
  #   admits it and no in-eval predicate excludes it (UNCOVERED-4).
  censusRow =
    id: l:
    # ★★ HALF-ATTRIBUTION IS REFUSED IN BOTH DIRECTIONS NOW, AND UNTIL THIS REVISION IT WAS REFUSED IN
    # ONE. §3 says `bead` and `construct` are ONE decision, not two — and the census selected on
    # `? bead` alone, so a hand-written leaf carrying `construct` WITHOUT `bead` was never a row at all.
    # Measured: `censusOf` over such a leaf returned `[ ]`, with the same-run control that the
    # bead-without-construct direction IS caught. A pair whose halves are refused asymmetrically is not
    # one decision; it is two, one of which happens to be checked. The selector below is widened to
    # match, and the cost is one extra WHNF-only `?` per leaf.
    # ★ SAFE ON TODAY'S TREE, MEASURED RATHER THAN ASSUMED: `construct`-binding lines in `ci/` + `parity/`
    #   number 0, against a same-run positive control of 224 files carrying `expected =` lines — so
    #   widening the selector admits no leaf that is not already a declaration.
    if !(l ? bead) then
      throw "G2 census: leaf `${id}` carries `construct` without `bead` — attribution is one decision, not two, and the half that names the tracker id is the half that is missing"
    else if !(l ? construct) then
      throw "G2 census: leaf `${id}` carries `bead` without `construct` — attribution is one decision, not two"
    else if !(beadShapeOk l.bead) then
      throw "G2 census: leaf `${id}` has a `bead` that G1 rejects — it attributes the known-fail to nothing"
    else if !(anchorResolves l.construct) then
      throw "G2 census: leaf `${id}` names a `construct` that is not bound in the governed source — G3 rejects it"
    # ★ NEW — `expr` IS REQUIRED, ON BOTH FORMS, AND IT WAS IN NEITHER THE BULLET LIST NOR THE CENSUS.
    # Both destructuring patterns take `expr`, so the sanctioned path cannot omit it; the census could,
    # and a leaf with no `expr` censused CLEAN as a four-key value row while ☢️-ing at the instrument.
    # It is form-INDEPENDENT, so it is checked ABOVE the form dispatch rather than once per arm.
    else if !(l ? expr) then
      throw "G2 census: leaf `${id}` carries no `expr` — a declared xfail with nothing to evaluate is not a test, and nix-unit reports the omission as an unnamed ☢️ rather than as a missing declaration"
    # ★★★ NEW, AND THIS CLAUSE MUST PRECEDE THE FORM DISPATCH — THE DISPATCH IS WHAT HID IT.
    #
    # §1's fifth bullet ("No `expected` on the error form") is a by-construction clause enforced by
    # `xfailError`'s pattern REFUSING the key, and it had no census check. Because `censusRow` dispatched
    # on `l ? expectedError` FIRST, adding one well-formed `expectedError` to a value-form leaf routed it
    # down the error arm and skipped BOTH remaining value clauses. Measured, one construction, controls in
    # the same run:
    #   degenerate value leaf (expected == correct) + expectedError → CLEAN six-key row; without the
    #     `expectedError`, the same leaf is refused BY NAME ("degenerate xfail")
    #   value leaf with no `correct` + expectedError            → CLEAN six-key row; without it, refused
    #     BY NAME ("without `correct`")
    #   and the admitted row is `==` to the row a LEGITIMATE error leaf produces, so a reviewer diffing
    #     the census literal cannot tell the two apart.
    # ★ AND THE INSTRUMENT DOES NOT CLOSE IT EITHER — F14c's generalisation is FALSE for a non-throwing
    #   `expr`: nix-unit runs such a leaf as a VALUE-form test and IGNORES `expectedError` silently, so
    #   the leaf goes ✅ GREEN while asserting nothing about the error it names. Every guard is closed on
    #   this input except the one §3 calls the only total enforcement point.
    # ★ BOTH DIRECTIONS, AND THE HARM IS ASYMMETRIC — stated rather than collapsed. `expected` alongside
    #   `expectedError` is the FAIL-OPEN (nix-unit switches form). `correct` alongside it is merely a
    #   half-written claim wearing keys of two forms. Both are refused, because both are guarantees the
    #   constructor's strict destructuring makes and the census exists to re-make on the hand-written path.
    else if l ? expectedError && (l ? expected || l ? correct) then
      throw "G2 census: leaf `${id}` carries `expectedError` alongside a VALUE-form key (`expected` or `correct`) — the two forms are disjoint, and nix-unit runs such a leaf as a value-form test with `expectedError` silently ignored"
    else if l ? expectedError then
      (
        # ★★ ABSENCE IS A DECISION ON THE ERROR FORM TOO, AND THIS IS THE ARM THAT HAD NO CHECK.
        # §1 makes `type` and `msg` REQUIRED because F14b measures that nix-unit reads an omitted field
        # as ANY KIND / ANY MESSAGE — a fail-open in the one axis the mechanism exists to exploit. The
        # constructor enforces that by strict destructuring. The CENSUS did not, and the census is the
        # only total enforcement point, so on the hand-written path — THE ENTIRE REASON G2 EXISTS —
        # required-ness had no check at all. Measured, four arms one construction:
        #   `msg` absent  → `attribute 'msg' missing` at the `msgIsTotal` call: an UNNAMED
        #                   missing-attribute EvalError `tryEval` cannot catch (F13), which is
        #                   precisely the error class this revision converts to a named refusal
        #                   ONE CLAUSE AWAY, at `!(l ? correct)`.
        #   `type` absent → STRICTLY WORSE. The row is built with `inherit (l.expectedError) type msg`,
        #                   which binds lazily: the census returns a STRUCTURALLY COMPLETE row — length
        #                   1, all six attrNames, `bead`/`construct`/`sites`/`msg` all reading cleanly —
        #                   with the error a thunk that surfaces only under deep force. It fails closed
        #                   on the SHIPPED path only by an accident of evaluation order, because §3
        #                   mandates `==` against a checked-in literal and `==` deep-forces.
        #   ★ AND THAT IS WHY UNCOVERED-4's MITIGATION HAD TO BE RE-STATED: its refutation reads "`nix
        #     eval` the census and read the row", and on the type-absent case that returns a PRINTABLE
        #     row with the error embedded — so the exhibition mitigation reads as intact when it is not.
        #   Controls, same run: a complete row censuses clean, and `msg = ".*"` is a NAMED refusal, so
        #   the floor is live and the instrument can refuse.
        if !(l.expectedError ? type) || !(l.expectedError ? msg) then
          throw "G2 census: leaf `${id}` is an error-form declared xfail whose `expectedError` omits `type` or `msg` — nix-unit reads an omitted field as ANY kind / ANY message, so the claim is half-written and the omission is invisible in the row"
        else if msgIsTotal l.expectedError.msg then
          throw "G2 census: leaf `${id}` declares a `msg` that matches EVERY message — such a pattern asserts nothing about the failure"
        else
          {
            inherit id;
            inherit (l) bead construct;
            sites = sitesOf l.construct;
            inherit (l.expectedError) type msg;
          }
      )
    # a value-form declared xfail must carry the WHOLE claim, or the degenerate clause is
    # unobservable from the leaf. Absence is a decision: `correct` is required, not defaulted.
    # ★ NEW — AND SO IS `expected`, WHICH THE r8 SWEEP CONVERTED ONE CLAUSE ABOVE AND NOT HERE.
    # `xfailValue`'s pattern takes `actual`, which becomes `expected` on the leaf, so required-ness is a
    # by-construction clause on this key exactly as it is on `correct`. Without this line the NEXT
    # clause reads `l.expected` off a leaf that has none: an UNNAMED missing-attribute EvalError that
    # `tryEval` cannot catch (F13) — measured as a ☢️ escaping through `builtins.sort`, i.e. the very
    # error class the `!(l ? correct)` clause directly below was added to convert. The sweep that added
    # that clause read the branches it was editing and not the keys they dereference.
    else if !(l ? expected) then
      throw "G2 census: leaf `${id}` is a value-form declared xfail without `expected` — the claim `today it is X` is missing its X, and reading the absent key is an EvalError `tryEval` cannot catch"
    else if !(l ? correct) then
      throw "G2 census: leaf `${id}` is a value-form declared xfail without `correct` — the claim `today it is X, it should be Y` is half-written, and the degenerate case cannot be seen"
    else if l.expected == l.correct then
      throw "G2 census: leaf `${id}` is a degenerate xfail — `expected` equals `correct`, so it claims today's value is also the right one"
    else
      { inherit id; inherit (l) bead construct; sites = sitesOf l.construct; };
  censusOf =
    tests:
    builtins.sort (a: b: a.id < b.id) (
      builtins.concatMap (
        s:
        builtins.concatMap (
          n:
          let l = tests.${s}.${n}; in
          # EITHER half of the attribution pair makes this a row. Selecting on `? bead` alone made the
          # census total over one half of a decision §3 calls indivisible.
          if l ? bead || l ? construct then [ (censusRow "${s}.${n}" l) ] else [ ]
        ) (builtins.attrNames tests.${s})
      ) (builtins.attrNames tests)
    );

  # ═══ §5 — suite-completeness (1)–(4), `attrNames` only. ═══════════════════════════════════════
  emptySuites = tests: builtins.filter (s: tests.${s} == { }) (builtins.attrNames tests);
  badPrefixLeaves =
    tests:
    builtins.concatMap (
      s: map (n: "${s}.${n}") (builtins.filter (n: builtins.match "test.*" n == null) (builtins.attrNames tests.${s}))
    ) (builtins.attrNames tests);
  nestedLeaves =
    tests:
    builtins.concatMap (
      s:
      map (n: "${s}.${n}") (
        builtins.filter (n: let v = tests.${s}.${n}; in builtins.isAttrs v && !(v ? expr)) (builtins.attrNames tests.${s})
      )
    ) (builtins.attrNames tests);
  # (4) the file census — the `boundary.nix` coreFiles/actualCore construction, over ci/tests.
  # The exclusion is the repo's OWN convention, not a hand-kept list: a `/_`-infixed path is what
  # import-tree/mkCi already skip as a flake-parts module (den-compat-test.nix's header states it).
  # Naming `_lib` alone misses `_fixtures/` and mis-counts by one on landing day — measured.
  actualTestFiles =
    let
      base = "${denHoagSrc}/ci/tests";
      walk =
        rel:
        let e = builtins.readDir "${base}/${rel}"; in
        builtins.concatMap (
          n:
          if e.${n} == "directory" then
            (if builtins.match "_.*" n != null then [ ] else walk "${rel}${n}/")
          else if isNix n then
            [ "${rel}${n}" ]
          else
            [ ]
        ) (builtins.attrNames e);
    in
    builtins.sort (a: b: a < b) (walk "");

  # ── fixtures ──────────────────────────────────────────────────────────────────────────────────
  okTests = {
    a = { test-one = { expr = 1; expected = 1; }; };
    b = { test-two = { expr = 2; expected = 2; }; };
  };
  declaredTests = {
    a = {
      test-one = xfail.value { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 0; actual = 0; correct = 3; };
    };
  };
  # THE FAIL-OPEN, as two fixtures: a red leaf, and the same leaf with `expected` edited in place
  # to the observed-wrong value. No bead, no construct, no census row, gate green.
  redTests = { a = { test-one = { expr = 0; expected = 3; }; }; };
  weakenedTests = { a = { test-one = { expr = 0; expected = 0; }; }; };
  # HAND-WRITTEN attribution — the path that bypasses every constructor. The census is what sees it.
  handBadBead = { a = { test-one = { expr = 0; expected = 3; correct = 3; bead = "TODO"; construct = "pipeOps"; }; }; };
  handBadConstruct = { a = { test-one = { expr = 0; expected = 3; correct = 3; bead = "den-hoag-gb9"; construct = "empty codomain"; }; }; };
  handHalfAttributed = { a = { test-one = { expr = 0; expected = 3; bead = "den-hoag-gb9"; }; }; };
  # ★ the OTHER half of the same pair — the direction the `? bead` selector could not see at all.
  handHalfAttributedConstructOnly = { a = { test-one = { expr = 0; expected = 3; construct = "pipeOps"; }; }; };
  # ★ the ERROR form's required fields, hand-written and OMITTED. `type` absent is the strictly worse
  #   case: the row builds, prints, and carries the error as a thunk.
  handNoErrorType = {
    a = { test-one = { expr = 0; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { msg = "boom"; }; }; };
  };
  handNoErrorMsg = {
    a = { test-one = { expr = 0; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; }; }; };
  };
  # ★ the two the r4 census could not see: a hand-written TOTAL `msg`, and a hand-written DEGENERATE
  #   value xfail (a test that really passes, permanently attributed known-fail).
  handTotalMsg = {
    a = { test-one = { expr = 0; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = ".*"; }; }; };
  };
  handDegenerate = { a = { test-one = { expr = 1; expected = 1; correct = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; }; }; };
  handNoCorrect = { a = { test-one = { expr = 0; expected = 0; bead = "den-hoag-gb9"; construct = "pipeOps"; }; }; };
  # ★★★ THE THREE FIXTURES OF THE r8 SWEEP'S OWN GAP — every one of them censused CLEAN before this
  #     revision, and the first two are the fail-open: a leaf that is GREEN at nix-unit while asserting
  #     nothing about the error it names, and INDISTINGUISHABLE in the reviewed census literal from a
  #     legitimate error declaration.
  # a DEGENERATE value-form xfail wearing one well-formed `expectedError`: routes down the error arm,
  # skipping BOTH the degenerate clause and the `? correct` clause.
  handBothFormsDegenerate = {
    a = { test-one = { expr = 1; expected = 1; correct = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = "boom"; }; }; };
  };
  # the same bypass reached from the other clause: no `correct` at all.
  handBothFormsNoCorrect = {
    a = { test-one = { expr = 1; expected = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = "boom"; }; }; };
  };
  # the OTHER direction of the same disjointness clause — `correct` on an error-form leaf. Not a
  # fail-open (nix-unit still runs it as an error test), but the same constructor guarantee.
  handErrorFormWithCorrect = {
    a = { test-one = { expr = 1; correct = 5; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = "boom"; }; }; };
  };
  # ★ `expr` — required by BOTH destructuring patterns, absent from §1's bullet list, and unchecked.
  handNoExprValueForm = { a = { test-one = { expected = 3; correct = 5; bead = "den-hoag-gb9"; construct = "pipeOps"; }; }; };
  handNoExprErrorForm = { a = { test-one = { bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = "boom"; }; }; }; };
  # ★ `expected` — the sibling of `? correct`, one clause below it, left as the uncatchable EvalError
  #   that the `? correct` clause was added to convert.
  handNoExpected = { a = { test-one = { expr = 0; correct = 5; bead = "den-hoag-gb9"; construct = "pipeOps"; }; }; };

  # ── ★★ THE §6b FIXTURE IS DERIVED FROM `assertionKeys`, NOT WRITTEN OUT ───────────────────────
  #
  # Revision 5's projection fixture was a hardcoded seven-key literal. Its generality clause then
  # quantified over `assertionKeys ∩ out` with `out` FIXED, so a key added to `assertionKeys` never
  # entered the fixture and the clause remained a statement about the six keys that happened to be
  # written down. (It quantified over nothing at all, for a second and independent reason — `?`
  # takes a LITERAL attr path, so `out ? k` asked for an attribute named `k`, the filter was `[ ]`
  # and `all p [ ]` held for any leaf including an empty one. That is `den-hoag-gg8`'s vacuous-over-
  # empty defect, in the file that names it below. Both are fixed here, and NEITHER fix alone
  # discriminates — measured.)
  #
  # Here the fixture IS the key list. The value lookup is TOTAL BY REFUSAL: the alternative to a key
  # entering the fixture is a NAMED throw, never a silent absence. Absence is a decision, and the
  # decision taken here is that an unvalued key stops the run rather than shrinking the quantifier.
  sampleValues = {
    bead = "den-hoag-gb9";
    construct = "pipeOps";
    correct = 3;
    expected = 0;
    expectedError = { type = "ThrownError"; msg = "boom"; };
    expr = 0;
  };
  sampleOf =
    k:
    if sampleValues ? ${k} then
      sampleValues.${k}
    else
      throw "xfail core fixture: `assertionKeys` gained `${k}` and `sampleValues` has no entry for it — the projection property cannot be exercised on a key the fixture cannot value";
  fleetFixture = { den = { hosts = { }; }; imports = [ ]; };
  # ★★★ THE EXCLUSION IS THE REFUSAL SET, AND NOTHING ELSE — MEASURED, NOT ASSUMED. The two forms are
  # disjoint in exactly the sense F14c measures: a leaf carrying BOTH `expected` and `expectedError` is
  # refused by name, so the error arm's fixture cannot carry `expected`.
  # ★★ REVISION 6 ALSO EXCLUDED `correct` HERE, ON THAT SAME STATED GROUND, AND THE GROUND IS FALSE OF
  # `correct`: nothing refuses an error-form leaf that carries it, the projection keeps it, and it
  # censuses cleanly end to end. That exclusion removed THE ONE INPUT SHAPE at which the projection and
  # a per-arm rebuild disagree at today's key list — from the fixture whose derivation was supposed to
  # make it general — and it is the whole reason revision 6 concluded no such input existed. A fixture
  # derived from a list is only as general as the exclusions carved out of it, and an exclusion is a
  # claim like any other: this one is now `testScaffoldErrorArmCarriesAValueFormKey`.
  formExclusive = {
    value = [ "expectedError" ];
    error = [ "expected" ];
  };
  # ★★ THE SAMPLE VALUES ARE FORCED HERE, AND THAT IS WHAT MAKES "TOTAL BY REFUSAL" TRUE OF THE
  # SCENARIO RATHER THAN OF A DIRECT CALL. `listToAttrs` binds lazily and every consumer below reaches
  # for `hasAttr`/`attrNames`, which never force a value. Measured on revision 6: a seventh key with no
  # `sampleValues` entry killed exactly the three rows §12 predicts — and `sampleOf`'s named message
  # appeared ZERO times in the output (positive control: 2 occurrences when the throw escapes). The
  # rows died on `keysQuantifiedOver` 5 → 6. The decision was right and the mechanism did not deliver
  # it; `forceValues` is the one line that puts the refusal where the decision is taken.
  forceValues = attrs: builtins.foldl' (a: k: builtins.seq attrs.${k} a) attrs (builtins.attrNames attrs);
  outOfForm =
    form:
    forceValues (
      fleetFixture
      // builtins.listToAttrs (
        map (k: { name = k; value = sampleOf k; }) (
          builtins.filter (k: !(elem k formExclusive.${form})) xfail.assertionKeys
        )
      )
    );
  assertionKeysOf = out: builtins.filter (k: builtins.hasAttr k out) xfail.assertionKeys;

  # ══ ★★★ THE FOIL — M21's CONSTRUCTION, WRITTEN DOWN RATHER THAN NAMED ════════════════════════════
  #
  # `namesInLineLocal` above is retained so the replaced extractor's failure is asserted beside the
  # replacement's success. This is that move for §6b, and revision 6 is the reason it is needed: it used
  # the phrase "a per-arm rebuild" for TWO DIFFERENT FUNCTIONS inside one argument — F37's six-key
  # `out ? k` rebuild, which is the projection longhand, and the per-arm one, which is not — and drew
  # the conclusion about the wrong one. A NAMED object cannot be measured; a written one can.
  #
  # This is M21's leaf construction: each arm enumerates the keys its own form declares, the key-list
  # argument ignored. The both-forms and neither-form refusals are omitted because `admissibleOuts`
  # cannot reach them; §12's M21 keeps them, which is why its kill set is attributable to carriage.
  perArmRebuild =
    out:
    let
      pick =
        ks:
        builtins.listToAttrs (
          map (k: { name = k; value = out.${k}; }) (builtins.filter (k: builtins.hasAttr k out) ks)
        );
      leaf =
        if builtins.hasAttr "expectedError" out then
          pick [ "bead" "construct" "expectedError" "expr" ]
        else
          pick [ "bead" "construct" "correct" "expected" "expr" ];
    in
    if builtins.hasAttr "expectedError" out then
      leaf
    else if builtins.isAttrs leaf.expected && builtins.isAttrs leaf.expr then
      leaf // { expr = builtins.intersectAttrs leaf.expected leaf.expr; }
    else
      leaf;

  # ★★ AND THE DOMAIN IS DERIVED FROM THE KEY LIST'S OWN DECLARED STRUCTURE, NOT LISTED BY HAND.
  # F37's spanning set was TEN HAND-CHOSEN INPUTS and the separating shape was not among them — a
  # hand-written fixture one level above the fixture this file had just finished deriving, which is the
  # defect this revision's §9 generalises. Here the domain is every `out` the scaffold ADMITS, built
  # from the structure `assertionKeys` already declares: `expr` always (nix-unit requires it), exactly
  # one of `formKeys` (both is refused, neither is refused), `attributionKeys` as a UNIT (one decision,
  # not two), and every remaining key free. Its size is a function of the list — `2 × 2 × 2^|free|` —
  # so a seventh assertion key doubles it and the asserted size goes red by name.
  subsetsOf = xs: builtins.foldl' (acc: x: acc ++ map (s: s ++ [ x ]) acc) [ [ ] ] xs;
  freeKeys =
    builtins.filter (k: k != "expr" && !(elem k xfail.formKeys) && !(elem k xfail.attributionKeys))
      xfail.assertionKeys;
  admissibleOuts =
    builtins.concatMap (
      fk:
      builtins.concatMap (
        att:
        map (
          # forced for the same reason `outOfForm` is: EVERY fixture in this file is total by refusal,
          # or the rule is a property of one call site rather than of the file.
          free:
          forceValues (builtins.listToAttrs (map (k: { name = k; value = sampleOf k; }) ([ "expr" fk ] ++ att ++ free)))
        ) (subsetsOf freeKeys)
      ) [ [ ] xfail.attributionKeys ]
    ) xfail.formKeys;
  separatingOuts = builtins.filter (out: xfail.scaffoldLeafOf out != perArmRebuild out) admissibleOuts;

  # ══ ★★★ THE SECOND FOIL — IT DISCHARGES THE ONE NEGATIVE EXISTENTIAL THIS DOCUMENT STILL MAKES ═════
  #
  # Sweeping the CLASS the withdrawal quantifies over — "negative existentials over assertions in this
  # document", not "sites stating the sentence that was refuted" — turns up a second one, and it is three
  # lines from the first. Revision 7 withdrew "no assertion at one key list separates the projection from
  # a per-arm rebuild" and left standing, in the same comment, "NATURALITY IN THE KEY SET — no assertion
  # at one list reaches this one". SAME CLAIM SHAPE. §9's own Rule 3 says a claim of that shape is
  # authorable only as extensional equality of two WRITTEN functions on a DERIVED domain, stated as a
  # NUMBER — and this one was stated as prose, in the revision that shipped Rule 3.
  #
  # So the second construction is written down as well. `keyListIgnoringScheme` ACCEPTS the key list and
  # IGNORES it, projecting at `assertionKeys` whatever it is handed. That is the exact foil this claim is
  # about, and it is NOT M21: M21 also rebuilds per arm, so it is separable at one key list and therefore
  # cannot witness a property whose whole content is that one key list is not enough.
  keyListIgnoringScheme = _keys: out: xfail.scaffoldLeafOfBy xfail.assertionKeys out;
  naturalityExtended = xfail.assertionKeys ++ [ "__naturalityProbe" ];
  naturalityDomain = map (out: out // { __naturalityProbe = 1; }) admissibleOuts;
  naturalitySeparatingAt =
    keys:
    builtins.filter (out: xfail.scaffoldLeafOfBy keys out != keyListIgnoringScheme keys out) naturalityDomain;

  # the retirement simulation: the same file body with the BINDING deleted and the explanatory
  # comment left behind — which is what a real retirement leaves.
  liveText = "  # recoverEmits recovers the codomain of a v1 policy.\n  recoverEmits =\n    args: name: gate: fn:\n      { };\n";
  retiredText = "  # formerly `recoverEmits` — retired; the codomain is now a query.\n  codomainOf = args: { };\n";
  # ★ the SAME retirement, but the explanatory note is left as a `''` documentation string rather
  #   than a `#` comment — the form revision 3's extractor could not distinguish from source.
  retiredDocText = "  doc = ''\n    Formerly:\n      recoverEmits =\n        args: name: gate: fn: { };\n  '';\n  codomainOf = args: { };\n";
  # ★ UNCOVERED-7's newly-enumerated vector: a `''` string OPENED AND CLOSED on one line that then
  #   carries a `#`. `stripHashTail` deletes the closing delimiter, so the bit inverts and STAYS
  #   inverted, and every following binding is lost. The control is the same body without the `#`.
  # ★ the `#` must be INSIDE the string for the vector to fire: `stripHashTail` then deletes the
  #   CLOSING `''` along with the comment tail, leaving an odd count. A `#` after the closing
  #   delimiter is harmless, which is why the control below carries one.
  oneLineDocHashText = "  doc = ''a # b'';\n  afterTheOneLiner = 1;\n";
  oneLineDocPlainText = "  doc = ''a b'';  # a hash OUTSIDE the string\n  afterTheOneLiner = 1;\n";

  # the 14 names that are binding-shaped ONLY inside a `''` string in the governed roots.
  docStringOnlyNames = [
    "action"
    "den.aspects.alice.includes"
    "den.aspects.my-disko.includes"
    "den.aspects.my-home.includes"
    "den.aspects.my-laptop.includes"
    "den.aspects.my-user.includes"
    "den.aspects.tux.includes"
    "den.aspects.vic.includes"
    "den.default.includes"
    "den.defaults.includes"
    "den.schema.home.includes"
    "den.schema.host.includes"
    "den.schema.user.includes"
    "options.flake.nixosConfigurations"
  ];
  lineLocalPairs =
    builtins.concatMap (
      r:
      builtins.concatMap (
        f: map (n: { name = n; file = "${r.prefix}${f}"; }) (namesInLineLocal (builtins.readFile "${denHoagSrc}/${r.dir}/${f}"))
      ) (filesOfRoot r)
    ) anchorRoots;
  lineLocalResolves = c: builtins.any (p: p.name == c) lineLocalPairs;
in
{
  # ── §1 the forms, and their by-construction clauses, on the NATIVE error channel (no tryEval:
  #    the tryEval idiom is the very shape den-hoag-30a files at 235 lines across 95 files, and
  #    F13 measures it cannot see an abort or a missing attribute anyway). ────────────────────────
  testValueFormShape = {
    expr = builtins.attrNames (xfail.value { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 0; actual = 0; correct = 3; });
    expected = [ "bead" "construct" "correct" "expected" "expr" ];
  };
  testErrorFormShape = {
    expr = builtins.attrNames (xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 0; type = "ThrownError"; msg = "compose commitment"; });
    expected = [ "bead" "construct" "expectedError" "expr" ];
  };
  # F14c: the forms are DISJOINT by construction — the error form cannot emit `expected`.
  testErrorFormHasNoExpected = {
    expr = (xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 0; type = "ThrownError"; msg = "boom"; }) ? expected;
    expected = false;
  };
  testDegenerateValueRefused = {
    expr = xfail.value { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 1; actual = 1; correct = 1; };
    expectedError = { type = "ThrownError"; msg = "degenerate xfail claims today's value"; };
  };
  testTotalMsgStarRefused = {
    expr = xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = ".*"; };
    expectedError = { type = "ThrownError"; msg = "matches EVERY message"; };
  };
  testTotalMsgEmptyRefused = {
    expr = xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = ""; };
    expectedError = { type = "ThrownError"; msg = "matches EVERY message"; };
  };
  # `x?` matches EVERY message under search semantics and is not obviously total; the old floor
  # (`msg != ""`) admits it.
  testTotalMsgOptionalRefused = {
    expr = xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = "x?"; };
    expectedError = { type = "ThrownError"; msg = "matches EVERY message"; };
  };
  # POSITIVE CONTROL for the floor, same run: it is not over-broad. `"."` is ACCEPTED — the stated
  # limit of the construction, asserted rather than described.
  testDotMsgAccepted = {
    expr = (xfail.error { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = "."; }).expectedError.msg;
    expected = ".";
  };

  # ══ ★★ THE WIRING — G1 AND G3 APPLIED BY THE CONSTRUCTOR ══════════════════════════════════════
  # Revision 3's kill, verbatim, asserted NOT TO BUILD. `bead` is diagnosed first because
  # `builtins.seq` forces the attribution before either form-specific clause.
  testR3KillLeafDoesNotBuild = {
    expr = xfail.value { bead = "TODO"; construct = "empty codomain"; expr = 0; actual = 0; correct = 3; };
    expectedError = { type = "ThrownError"; msg = "G1 rejects it"; };
  };
  testWiredG1RefusesMalformedBead = {
    expr = xfail.value { bead = "TODO"; construct = "pipeOps"; expr = 0; actual = 0; correct = 3; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  # F5's four in-tree bead-shaped strings are English. An unanchored regex would accept them.
  testWiredG1RefusesEnglishBeadShape = {
    expr = xfail.value { bead = "den-hoag-absent"; construct = "pipeOps"; expr = 0; actual = 0; correct = 3; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  # ★ the phrase `lib/concern-policies.nix` uses for the defect behind two of the six declarations —
  #   the most natural value an author would write. Under whole-file `hasInfix` it RESOLVED, at a
  #   comment. Under revision 3 it built anyway, because nothing consulted G3. It now cannot build.
  testWiredG3RefusesProse = {
    expr = xfail.value { bead = "den-hoag-9xo.75"; construct = "empty codomain"; expr = 0; actual = 0; correct = 1; };
    expectedError = { type = "ThrownError"; msg = "not bound in the governed source"; };
  };
  testWiredG3RefusesAbsentToken = {
    expr = xfail.error { bead = "den-hoag-gb9"; construct = "__xfail_anchor_negative_control__"; expr = 1; type = "ThrownError"; msg = "boom"; };
    expectedError = { type = "ThrownError"; msg = "not bound in the governed source"; };
  };
  # the ERROR form is wired too — the guards are on the shared constructor, not copied per form.
  testWiredG1RefusesOnErrorForm = {
    expr = xfail.error { bead = "TODO"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = "boom"; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  # ★ POSITIVE CONTROL for the whole wiring, same run: a leaf that satisfies G1 and G3 BUILDS, and
  #   builds to the same shape it had before the guards existed. Without this the four refusals
  #   above are also satisfied by a constructor that refuses everything.
  testWiredGuardsAdmitAGoodLeaf = {
    expr = xfail.value { bead = "den-hoag-9xo.75"; construct = "recoverEmits"; expr = 0; actual = 0; correct = 1; };
    expected = { bead = "den-hoag-9xo.75"; construct = "recoverEmits"; correct = 1; expected = 0; expr = 0; };
  };

  # ══ ★ `builtins.seq` — THE PROPERTY, COVERED. ═════════════════════════════════════════════════
  # Both leaves below violate the attribution clause AND the form-specific clause. `seq` forces the
  # attribution first, so the diagnosis is the one the author needs; without it the form-specific
  # clause is the `if` condition and always wins, and the author is told their `msg` is too broad
  # when their real defect is that the bead names nothing. Deleting `seq` from all three producers
  # left revision 4 at 51/51, exit 0 — these two are the only instruments that see it, and §12's M14a
  # is the measurement (it kills exactly these two and nothing else).
  testSeqDiagnosesAttributionFirstOnErrorForm = {
    expr = xfail.error { bead = "TODO"; construct = "pipeOps"; expr = 1; type = "ThrownError"; msg = ".*"; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  testSeqDiagnosesAttributionFirstOnValueForm = {
    expr = xfail.value { bead = "TODO"; construct = "pipeOps"; expr = 1; actual = 1; correct = 1; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };

  # ── §3 G1, the predicate ─────────────────────────────────────────────────────────────────────
  testG1Shape = {
    expr = map beadShapeOk [ "den-hoag-9uv" "den-hoag-4kh.53.64" "den-hoag-gb9" "TODO" "den-hoag-absent" "" ];
    expected = [ true true true false false false ];
  };

  # ── §3 G3 — the index ────────────────────────────────────────────────────────────────────────
  testG3RejectsProse = {
    expr = map anchorResolves [ "empty codomain" "the" "compose commitment law" "staged pre-pass / compose-commitment law" ];
    expected = [ false false false false ];
  };
  testG3AcceptsRealBindings = {
    expr = map anchorResolves [ "pipeOps" "recoverEmits" ];
    expected = [ true true ];
  };
  # ★ §9's register claim, made executable. Entry 1's residue `classBucketsOf` is a binding name and
  #   is anchorable TODAY — r4's §9 said it was "asserted in the index at §12's control set" while
  #   the name appeared nowhere in this file. It is asserted here, at its site.
  testG3AnchorsRegisterResidue = {
    expr = sitesOf "classBucketsOf";
    expected = [ "lib/attributes/output-modules.nix" ];
  };
  # ★ the RETIREMENT property §7 claims, made executable — and the replaced mechanism failing it in
  #   the same run. A retirement that leaves an explanatory comment keeps `hasInfix` green.
  testRetirementDropsAnchor = {
    expr = {
      live = elem "recoverEmits" (namesIn liveText);
      retired = elem "recoverEmits" (namesIn retiredText);
      hasInfixWouldSurvive = hasInfix "recoverEmits" retiredText;
    };
    expected = { live = true; retired = false; hasInfixWouldSurvive = true; };
  };
  # ★★ THE SAME PROPERTY WHEN THE NOTE IS LEFT AS A `''` DOC STRING — the vector revision 3's
  #    line-local extractor could not see. Its own extractor is run on the same body in the same
  #    assertion and KEEPS the anchor: the replacement's success and the replaced form's failure,
  #    side by side.
  testRetirementDropsAnchorThroughDocString = {
    expr = {
      retired = elem "recoverEmits" (namesIn retiredDocText);
      lineLocalWouldSurvive = elem "recoverEmits" (namesInLineLocal retiredDocText);
      hasInfixWouldSurvive = hasInfix "recoverEmits" retiredDocText;
    };
    expected = { retired = false; lineLocalWouldSurvive = true; hasInfixWouldSurvive = true; };
  };
  # ★ UNCOVERED-7's second vector, PINNED RATHER THAN DESCRIBED. A one-line `''` string followed by
  #   a `#` inverts the bit and it stays inverted, so `afterTheOneLiner` is lost. The control is the
  #   identical body without the `#`, in the same assertion: there the binding survives. Zero
  #   instances in the governed roots (measured, with a same-run positive control on a fixture).
  testG3OneLineDocStringWithHashInvertsBit = {
    expr = {
      withHash = elem "afterTheOneLiner" (namesIn oneLineDocHashText);
      control = elem "afterTheOneLiner" (namesIn oneLineDocPlainText);
    };
    expected = { withHash = false; control = true; };
  };
  # ★★ THE 14 LIVE PHANTOMS, on the real tree. Each is binding-shaped inside a `''` string and bound
  #    nowhere: `lib/compat/batteries.nix` usage docs, `lib/compat/flake-outputs.nix`'s `message`,
  #    and `lib/compat/nh.nix`'s shell body. The line-local extractor admits every one of them, in
  #    the same assertion — so this is a measurement of the difference, not a description of it.
  testG3ExcludesDocStringOnlyNames = {
    expr = {
      admittedByIndex = builtins.filter anchorResolves docStringOnlyNames;
      admittedByLineLocal = builtins.length (builtins.filter lineLocalResolves docStringOnlyNames);
    };
    expected = { admittedByIndex = [ ]; admittedByLineLocal = 14; };
  };
  # ★ POSITIVE CONTROL for the `''` bit, same run. The extractor must not simply drop everything
  #   near a doc string: `message` is the binding that OPENS `flake-outputs.nix`'s doc string and is
  #   real; the six `lib/compat/nh.nix` bindings that follow its `''` shell body are real. A tracker
  #   that mishandles the `''${` escape on nh.nix:46 loses all six — measured, and refused.
  testG3KeepsBindingsAroundDocStrings = {
    expr = map anchorResolves [ "message" "denApps" "denPackages" "denShell" "hostApps" "homeApps" "buildInputs" ];
    expected = [ true true true true true true true ];
  };
  # ★ reads, not just comments, drop out: pipeOps has 4 occurrences under lib/*.nix but ONE binding
  #   site; the other three are `or`-guarded reads in a DIFFERENT file that survive its deletion.
  testG3SitesAreDefinitionsNotOccurrences = {
    expr = { pipeOps = sitesOf "pipeOps"; recoverEmits = sitesOf "recoverEmits"; };
    expected = {
      pipeOps = [ "lib/concern-policies.nix" ];
      recoverEmits = [ "lib/compat/policy-recover.nix" ];
    };
  };
  # ★★ THE HAYSTACK CENSUS. `contributingDirs` is `filesOfRoot` mapped to directories, so it cannot
  #    be green while the walk that feeds the index has stopped descending. Revision 3's three
  #    top-level controls were green with 22 files and 20.7 % of the name-pairs silently gone; this
  #    goes red on the same mutation, and on a skipped subtree, because the datum IS the file list.
  testG3ContributingDirs = {
    expr = builtins.listToAttrs (map (r: { name = r.name; value = contributingDirs r; }) anchorRoots);
    expected = {
      core = [ "" "attributes/" "output/" ];
      compat = [ "" "legacy/" "legacy/batteries/" "parity/" ];
      harness = [ "" ];
    };
  };
  # ★ PER-ROOT CONTROLS, kept, and stated for what they prove: the walk reached each root AT ALL.
  #   They name a binding that is NOT a construct — a control whose own binding is scheduled for
  #   deletion goes red for a reason unrelated to the property it guards.
  testG3RootsAllReached = {
    expr = {
      core = sitesOf "buildRoots";
      compat = sitesOf "compilePolicy";
      harness = sitesOf "denTest";
    };
    expected = {
      core = [ "lib/build-roots.nix" ];
      compat = [ "lib/compat/compile.nix" ];
      harness = [ "ci/tests/_lib/den-compat-test.nix" ];
    };
  };
  # ★ ...and BELOW top level, which is what revision 3's controls could not see. At depth 2
  #   (`lib/compat/legacy/batteries/`) NO uniquely-sited binding exists — every name there is also
  #   bound elsewhere — so a named control CANNOT be written for it, and `testG3ContributingDirs`
  #   is the only instrument that reaches it. Stated here rather than left as a silent gap.
  testG3DepthSitedBindingsReached = {
    expr = {
      coreDepth1 = sitesOf "prepareModules";
      compatDepth1 = sitesOf "assertEdgeParity";
      compatLegacy = sitesOf "selfIncludesOf";
    };
    expected = {
      coreDepth1 = [ "lib/output/terminal.nix" ];
      compatDepth1 = [ "lib/compat/parity/schema.nix" ];
      compatLegacy = [ "lib/compat/legacy/self-provide.nix" ];
    };
  };
  testG3NegativeControl = {
    expr = anchorResolves "__xfail_anchor_negative_control__";
    expected = false;
  };
  # STATED NON-COVERAGE, asserted: a short generic name resolves for a reason unrelated to the
  # claim. `sites` puts it in the census diff rather than hiding it.
  testG3AdmitsGenericNames = {
    expr = builtins.length (sitesOf "ops") > 0;
    expected = true;
  };
  # ...and a collision can span two ROOTS: `fail` is bound in core AND in compat. `sites` is what
  # puts that in the census diff instead of hiding it behind a boolean.
  testG3CollisionSpansRoots = {
    expr = sitesOf "fail";
    expected = [ "lib/compat/errors.nix" "lib/errors.nix" ];
  };

  # ── §3 G2 — the census, AND ITS ENFORCEMENT ──────────────────────────────────────────────────
  testG2CensusRow = {
    expr = censusOf declaredTests;
    expected = [ { id = "a.test-one"; bead = "den-hoag-gb9"; construct = "pipeOps"; sites = [ "lib/concern-policies.nix" ]; } ];
  };
  # ★ AN ERROR-FORM ROW CARRIES `type` AND `msg`. Revision 4's §3 claimed this while `censusRow`
  #   emitted four keys, so "weakening a `msg` to `.` is a reviewed diff hunk" was measured FALSE
  #   and UNCOVERED-4's whole mitigation sourced from it. The fields are bounded strings by
  #   construction, which is why they ride in the row while `expected`/`correct` — test values of
  #   unbounded size — do not: a census carrying those is the baseline-file shape §1 rejects.
  testG2ErrorRowCarriesTypeAndMsg = {
    expr = censusOf {
      a = { test-one = xfail.error { bead = "den-hoag-9xo.75"; construct = "recoverEmits"; expr = 1; type = "ThrownError"; msg = "empty recovery"; }; };
    };
    expected = [
      {
        id = "a.test-one";
        bead = "den-hoag-9xo.75";
        construct = "recoverEmits";
        sites = [ "lib/compat/policy-recover.nix" ];
        type = "ThrownError";
        msg = "empty recovery";
      }
    ];
  };
  testG2EmptyWhenNothingDeclared = {
    expr = censusOf okTests;
    expected = [ ];
  };
  # ★★ THE SECOND ENFORCEMENT POINT. These leaves never touched a constructor — they are
  #    hand-written attrsets, the one path no constructor can guard. The census is total over
  #    `? bead`, which IS the definition of a declared xfail, so it sees them. All FOUR of §1's
  #    by-construction clauses are re-checked here, not two.
  testG2RefusesHandWrittenBadBead = {
    expr = censusOf handBadBead;
    expectedError = { type = "ThrownError"; msg = "a `bead` that G1 rejects"; };
  };
  testG2RefusesHandWrittenBadConstruct = {
    expr = censusOf handBadConstruct;
    expectedError = { type = "ThrownError"; msg = "not bound in the governed source"; };
  };
  testG2RefusesHalfAttribution = {
    expr = censusOf handHalfAttributed;
    expectedError = { type = "ThrownError"; msg = "carries `bead` without `construct`"; };
  };
  # ★★ ...AND THE OTHER DIRECTION, WHICH WAS NOT A ROW AT ALL. `censusOf` selected on `? bead`, so a
  #    hand-written `construct` without a `bead` censused as `[ ]` — silently, under a §3 sentence
  #    saying the two are ONE decision. Refusing a pair in one direction only is refusing two things,
  #    one of them not at all.
  testG2RefusesHalfAttributionConstructOnly = {
    expr = censusOf handHalfAttributedConstructOnly;
    expectedError = { type = "ThrownError"; msg = "carries `construct` without `bead`"; };
  };
  # ★★ ABSENCE IS A DECISION ON THE ERROR FORM. §1 makes `type` and `msg` required BECAUSE F14b measures
  #    nix-unit reading an omitted field as ANY kind / ANY message. The constructor enforced it by strict
  #    destructuring and the census did not, so on the hand-written path — the whole reason G2 exists —
  #    the strictly WORSE of the two fail-opens had no check.
  testG2RefusesErrorRowWithoutType = {
    expr = censusOf handNoErrorType;
    expectedError = { type = "ThrownError"; msg = "omits `type` or `msg`"; };
  };
  testG2RefusesErrorRowWithoutMsg = {
    expr = censusOf handNoErrorMsg;
    expectedError = { type = "ThrownError"; msg = "omits `type` or `msg`"; };
  };
  # ★ NEW — the two clauses r4's census did not re-check. Both are hand-written, i.e. exactly the
  #   path the constructor cannot reach.
  testG2RefusesHandWrittenTotalMsg = {
    expr = censusOf handTotalMsg;
    expectedError = { type = "ThrownError"; msg = "matches EVERY message"; };
  };
  testG2RefusesHandWrittenDegenerate = {
    expr = censusOf handDegenerate;
    expectedError = { type = "ThrownError"; msg = "degenerate xfail"; };
  };
  # ...and the reason the degenerate clause is re-checkable at all: `correct` rides on the leaf, so
  # a value-form declaration missing it is a half-written claim and is refused rather than skipped.
  testG2RefusesValueRowWithoutCorrect = {
    expr = censusOf handNoCorrect;
    expectedError = { type = "ThrownError"; msg = "without `correct`"; };
  };
  # ★★★ THE r8 SWEEP'S OWN GAP, CLOSED — ROWS 5, 8-first-half AND 9 OF THE PRINTED ENUMERATION.
  #     Each of these six fixtures censused CLEAN before this revision. The first two are the fail-open
  #     proper: nix-unit runs them as VALUE-form tests, `expectedError` silently ignored, ✅ GREEN.
  testG2RefusesBothFormsOnADegenerateLeaf = {
    expr = censusOf handBothFormsDegenerate;
    expectedError = { type = "ThrownError"; msg = "alongside a VALUE-form key"; };
  };
  testG2RefusesBothFormsWithoutCorrect = {
    expr = censusOf handBothFormsNoCorrect;
    expectedError = { type = "ThrownError"; msg = "alongside a VALUE-form key"; };
  };
  testG2RefusesCorrectOnTheErrorForm = {
    expr = censusOf handErrorFormWithCorrect;
    expectedError = { type = "ThrownError"; msg = "alongside a VALUE-form key"; };
  };
  testG2RefusesValueRowWithoutExpr = {
    expr = censusOf handNoExprValueForm;
    expectedError = { type = "ThrownError"; msg = "carries no `expr`"; };
  };
  testG2RefusesErrorRowWithoutExpr = {
    expr = censusOf handNoExprErrorForm;
    expectedError = { type = "ThrownError"; msg = "carries no `expr`"; };
  };
  testG2RefusesValueRowWithoutExpected = {
    expr = censusOf handNoExpected;
    expectedError = { type = "ThrownError"; msg = "without `expected`"; };
  };
  # ★★ AND THE PROPERTY THAT MAKES ROW 9 A FAIL-OPEN RATHER THAN A TIDY-UP, ASSERTED RATHER THAN
  #    DESCRIBED: before the clause, the admitted row was `==` to the row a LEGITIMATE error leaf
  #    produces, so the second artifact a human diffs could not carry the difference. The refusal is
  #    what restores the distinction — this test asserts that the legitimate leaf STILL censuses, so
  #    the clause is not simply refusing the error form outright.
  testG2StillAdmitsTheLegitimateErrorForm = {
    expr = censusOf {
      a = { test-one = { expr = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; expectedError = { type = "ThrownError"; msg = "boom"; }; }; };
    };
    expected = [
      { id = "a.test-one"; bead = "den-hoag-gb9"; construct = "pipeOps"; sites = [ "lib/concern-policies.nix" ]; type = "ThrownError"; msg = "boom"; }
    ];
  };
  # ★ THE ENFORCEMENT COMPOSITION, asserted as a property of the census rather than of a fixture:
  #   every row a census can produce satisfies G1 and G3, because producing the row is what checks
  #   them. The positive control is that the census is non-empty — an empty census satisfies this
  #   vacuously, which is the `all p [ ]` defect den-hoag-gg8 tracks.
  testG2EveryCensusRowSatisfiesBothGuards = {
    expr =
      let c = censusOf (declaredTests // { b = { test-two = xfail.error { bead = "den-hoag-9xo.75"; construct = "recoverEmits"; expr = 1; type = "ThrownError"; msg = "empty recovery"; }; }; }); in
      {
        rows = builtins.length c;
        allBeadsOk = builtins.all (r: beadShapeOk r.bead) c;
        allAnchorsResolve = builtins.all (r: anchorResolves r.construct) c;
        allSitesNonEmpty = builtins.all (r: r.sites != [ ]) c;
      };
    expected = { rows = 2; allBeadsOk = true; allAnchorsResolve = true; allSitesNonEmpty = true; };
  };
  # ★★ THE FAIL-OPEN, PINNED. The mechanism is OPT-IN: nothing compels a red to become a declared
  #    xfail. An author facing a red may edit `expected` in place — no bead, no construct, no census
  #    row, and G2's output is byte-identical. This is a TRIPWIRE ON THE DISCLOSURE, not a
  #    measurement: the equality follows definitionally from `if l ? bead`, and it is asserted so
  #    that a later change which made the census non-blind would have to delete this test and
  #    UNCOVERED-1 with it. Its sibling is the positive control that G2 is not simply inert.
  testG2BlindToInPlaceWeakening = {
    expr = censusOf redTests == censusOf weakenedTests;
    expected = true;
  };
  testG2SeesADeclaration = {
    expr = censusOf declaredTests != censusOf redTests;
    expected = true;
  };

  # ── §5 suite-completeness, BOTH arms ─────────────────────────────────────────────────────────
  testSC1EmptySuiteCaught = {
    expr = emptySuites (okTests // { c = { }; });
    expected = [ "c" ];
  };
  testSC1CleanTreePasses = { expr = emptySuites okTests; expected = [ ]; };
  testSC2BadPrefixCaught = {
    expr = badPrefixLeaves { a = { test-ok = { expr = 1; expected = 1; }; helper = { expr = 1; expected = 1; }; }; };
    expected = [ "a.helper" ];
  };
  testSC2CleanTreePasses = { expr = badPrefixLeaves okTests; expected = [ ]; };
  testSC3NestingCaught = {
    expr = nestedLeaves { a = { test-group = { test-inner = { expr = 1; expected = 1; }; }; }; };
    expected = [ "a.test-group" ];
  };
  testSC3CleanTreePasses = { expr = nestedLeaves okTests; expected = [ ]; };
  # (4) over the REAL tree — the walk resolves and excludes `_`-prefixed directories.
  testSC4WalkMatchesDeclaringFiles = {
    expr = {
      count = builtins.length actualTestFiles;
      anyUnderscoreDir = builtins.any (f: hasInfix "_lib/" f || hasInfix "_fixtures/" f || hasInfix "_probes/" f) actualTestFiles;
      hasKnownFile = elem "boundary.nix" actualTestFiles;
    };
    # ★★★ THIS IS THE ONE ASSERTION IN THE CORE WHOSE VALUE IS A PROPERTY OF A SECOND REPOSITORY, AND
    # IT IS THEREFORE REV-INDEXED BY CONSTRUCTION. 203 = F19's declaring-file count at den-hoag
    # `0716eec`, measured this session against a CLEAN working tree. It read 202 at `9379610` and moved
    # when `ci/tests/containment-edges.nix` landed — the r8 gate saw the same +1 as a STAGED file in
    # another agent's tree, at unchanged HEAD, and this revision saw it again as a commit.
    # ⇒ The green set is not a property of these two files alone. §12 declares the den-hoag state every
    # number in it was taken against, and §14 carries the declaration as a limit rather than a caveat.
    # The `_`-prefix rule is what makes the walk agree with F19; excluding `_lib` alone yields 204
    # (ci/tests/_fixtures/fleet.nix declares no suite). The three suites this spec adds raise it to 206
    # on landing — §5 states the post-landing value.
    expected = { count = 203; anyUnderscoreDir = false; hasKnownFile = true; };
  };

  # ── §6b the scaffold's leaf construction, BOTH ARMS ──────────────────────────────────────────
  # The defect a literal reading of "one definition, two uses" produces: emitting `assertionKeys`
  # verbatim puts BOTH `expected` and `expectedError` on the leaf, which is ☢️ on EVERY
  # scaffold-hosted error test. The error arm cannot do it — `expected` is not in its construction.
  # ★★ `den-hoag-6p9` AS A REGRESSION TEST. The shipped error arm returns
  #    `{ expr = (tryEval …).success; expected = false; }` — `expectedError` ERASED, so `type` and
  #    `msg` never reach nix-unit and every error-form declaration is unfalsifiable. Under the
  #    projection the error arm reshapes nothing and the authored `expectedError` arrives intact.
  testScaffoldErrorArmForwardsExpectedError = {
    expr = (denTestLeaf {
      expr = 1;
      expectedError = { type = "ThrownError"; msg = "compose commitment"; };
      bead = "den-hoag-9xo.75";
      construct = "recoverEmits";
    }).expectedError;
    expected = { type = "ThrownError"; msg = "compose commitment"; };
  };
  # ...and the leaf is exactly the projection, with no `expected` invented and none dropped.
  testScaffoldErrorLeafShape = {
    expr = builtins.attrNames (
      denTestLeaf {
        expr = 1;
        expectedError = { type = "ThrownError"; msg = "boom"; };
        bead = "den-hoag-9xo.75";
        construct = "recoverEmits";
      }
    );
    expected = [ "bead" "construct" "expectedError" "expr" ];
  };
  # ★ THE BEHAVIOUR CHANGE THE PROJECTION FORCES, ASSERTED RATHER THAN LEFT TO BE DISCOVERED.
  #   Revision 4's rebuild dropped `expected` SILENTLY when an author wrote both keys. A projection
  #   cannot drop it, so the disjointness of the two forms (F14c) becomes an explicit refusal with a
  #   message instead of an unexplained ☢️ from nix-unit.
  testScaffoldRefusesBothAssertionForms = {
    expr = denTestLeaf {
      expr = 1;
      expected = false;
      expectedError = { type = "ThrownError"; msg = "boom"; };
      bead = "den-hoag-9xo.75";
      construct = "recoverEmits";
    };
    expectedError = { type = "ThrownError"; msg = "declares BOTH `expected` and `expectedError`"; };
  };
  # ★★ THE PARTITION ON THE VALUE ARM, over a fixture DERIVED FROM `assertionKeys`. The generality
  #    clause quantifies with `builtins.hasAttr`, not `?`: `?` takes a LITERAL attr path, so
  #    revision 5's `out ? k` asked for an attribute NAMED `k`, the domain was `[ ]`, and
  #    `all p [ ]` held for an empty leaf. `keysQuantifiedOver` asserts the domain SIZE beside the
  #    universal, which is the general repair for that class — a quantifier whose domain nobody
  #    checks is `den-hoag-gg8` one step back.
  # ★ WHAT THIS TEST DOES AND DOES NOT SURVIVE A KEY ADDITION. The generality clause extends with no
  #   edit: the new key enters `out` from the list and is quantified over. The three CARDINALITY
  #   clauses do not, and that is deliberate — they go red by name, so a key addition cannot pass
  #   through this test silently in either direction. The only two outcomes of adding a seventh key
  #   are a named `sampleValues` refusal and a red count. Neither is a silent green.
  # ★★ AND THIS ROW IS NOT ONE OF THE ROWS A PER-ARM REBUILD FAILS, which is a fact about the FIXTURE
  #    and not about the arity. Its `out` is the VALUE slice, which carries no error-form key, so the
  #    projection and a per-arm rebuild agree on it and M21 leaves this row green. The rows that do
  #    separate them are `testScaffoldErrorLeafIsTheProjectionOfOut` and
  #    `testScaffoldErrorArmCarriesAValueFormKey`, both below, both at TODAY's key list.
  testScaffoldLeafIsTheProjectionOfOut = {
    expr =
      let
        out = outOfForm "value";
        leaf = denTestLeaf out;
        fleet = xfail.fleetPartOf out;
      in
      {
        # every assertion key `out` carries is on the leaf
        carriesEveryAssertionKey = builtins.all (k: builtins.hasAttr k leaf) (assertionKeysOf out);
        # ...over a domain of asserted size, so the universal cannot be vacuously true
        keysQuantifiedOver = builtins.length (assertionKeysOf out);
        # and nothing else is
        leafHasNoFleetKeys = (leaf ? den) || (leaf ? imports);
        # the complement is exact: the fleet part is everything the leaf is not
        fleetKeys = builtins.attrNames fleet;
        # …and the two are disjoint and together cover `out`
        partitionIsExact =
          builtins.length (builtins.attrNames leaf) + builtins.length (builtins.attrNames fleet)
          == builtins.length (builtins.attrNames out);
      };
    expected = {
      carriesEveryAssertionKey = true;
      keysQuantifiedOver = 5;
      leafHasNoFleetKeys = false;
      fleetKeys = [ "den" "imports" ];
      partitionIsExact = true;
    };
  };
  # ...and the SAME derived construction on the error arm, whose fixture is the complementary slice
  # of the same list. Both arms are exercised by derivation, so neither has a fixture of its own.
  # ★★★ AND THIS ROW IS NOW A SEPARATOR AT TODAY'S KEY LIST, WHICH IS THE WHOLE OF REVISION 7's
  #     CORRECTION. Its `out` carries `correct` — a key the error FORM does not declare and the key
  #     LIST does — so a construction whose carried set depends on the arm drops it and both
  #     `carriesEveryAssertionKey` and `partitionIsExact` go false. Revision 6 excluded exactly this key
  #     from exactly this fixture and then concluded that no assertion at one key list could separate
  #     the two constructions. M21 dies here as well as at the extension test.
  testScaffoldErrorLeafIsTheProjectionOfOut = {
    expr =
      let
        out = outOfForm "error";
        leaf = denTestLeaf out;
        fleet = xfail.fleetPartOf out;
      in
      {
        carriesEveryAssertionKey = builtins.all (k: builtins.hasAttr k leaf) (assertionKeysOf out);
        keysQuantifiedOver = builtins.length (assertionKeysOf out);
        fleetKeys = builtins.attrNames fleet;
        partitionIsExact =
          builtins.length (builtins.attrNames leaf) + builtins.length (builtins.attrNames fleet)
          == builtins.length (builtins.attrNames out);
      };
    expected = {
      carriesEveryAssertionKey = true;
      keysQuantifiedOver = 5;
      fleetKeys = [ "den" "imports" ];
      partitionIsExact = true;
    };
  };
  # ★★★ THE SEPARATOR, NAMED FOR THE PROPERTY IT ASSERTS RATHER THAN FOR THE FIXTURE IT USES.
  #     FORM-INDEPENDENCE: what the leaf carries is a function of the KEY LIST and `out`, never of
  #     which arm ran. The error form does not declare `correct`; the key list does; so the leaf keeps
  #     it. A per-arm rebuild cannot — and that is the assertion revision 6 said did not exist, at
  #     today's key list, with no scheme and no extension involved.
  #     ★ Its positive control is `testScaffoldErrorLeafShape` in the same run: the same arm on an
  #     `out` WITHOUT `correct` yields four keys, so this row is the key being carried, not the leaf
  #     being wide.
  testScaffoldErrorArmCarriesAValueFormKey = {
    expr = builtins.attrNames (
      denTestLeaf {
        expr = 1;
        expectedError = { type = "ThrownError"; msg = "boom"; };
        correct = 3;
        bead = "den-hoag-9xo.75";
        construct = "recoverEmits";
      }
    );
    expected = [ "bead" "construct" "correct" "expectedError" "expr" ];
  };
  # ★★★ ...AND THE SAME PROPERTY AS AN EXTENSIONAL COMPARISON OVER A DERIVED DOMAIN, WHICH IS WHAT F37
  #     SHOULD HAVE BEEN. The two constructions are WRITTEN (`scaffoldLeafOf`, `perArmRebuild`), not
  #     named, and the domain is generated from `assertionKeys`' declared structure rather than chosen.
  #     `separating` is the number this file was implicitly claiming to be ZERO; it is 2. Asserting the
  #     domain size beside it is the same discipline `keysQuantifiedOver` applies one level down — a
  #     count nobody checks is a quantifier over nothing.
  testPerArmRebuildIsSeparableAtTodaysKeyList = {
    expr = {
      domainSize = builtins.length admissibleOuts;
      separating = builtins.length separatingOuts;
      dropped = map (
        out:
        builtins.filter (k: !(builtins.hasAttr k (perArmRebuild out))) (
          builtins.attrNames (xfail.scaffoldLeafOf out)
        )
      ) separatingOuts;
    };
    expected = {
      domainSize = 8;
      separating = 2;
      dropped = [ [ "correct" ] [ "correct" ] ];
    };
  };
  # ★★★ THE NATURALITY ROW — ONE OF FIVE ROWS A PER-ARM REBUILD FAILS, AND THE ONLY ONE OF THE FIVE
  #     THAT NEEDS A SECOND KEY LIST.
  #
  # ★★★ THE SENTENCE THAT STOOD HERE FOR TWO REVISIONS IS WITHDRAWN, AND IT WAS THE LAST SITE OF THE
  # WITHDRAWAL REVISION 7 REPORTED AS COMPLETE. It read: "F37 measures a correct per-arm rebuild and
  # the projection to be THE SAME FUNCTION on today's key set, over a spanning input set … Two
  # constructions that agree on every input of one key list are separated by NO assertion evaluated at
  # that key list — the shipped-battery mutant M21 confirms it." Every clause of it is refuted, and two
  # of them are refuted by definitions in THIS FILE, 35 and 65 lines above where the sentence sat:
  #   • "THE SAME FUNCTION" was the equivocation. F37's object enumerates all six keys under `out ? k`,
  #     which IS the projection; M21's object enumerates per arm, and is not.
  #   • "a spanning input set" was TEN HAND-CHOSEN INPUTS, which `admissibleOuts` replaced.
  #   • "M21 CONFIRMS IT" is MEASURED FALSE. M21 kills SIX, and TWO of the six are evaluated at
  #     today's key list — `testScaffoldErrorLeafIsTheProjectionOfOut` and
  #     `testScaffoldErrorArmCarriesAValueFormKey`. Under the narrowest reading of the mutation, the
  #     one that edits the leaf construction and leaves the scheme untouched, those two are the ONLY
  #     rows M21 kills. M21 refutes the sentence it was cited as confirming.
  # ★★ WHY REVISION 7's SWEEP MISSED IT, WHICH IS THE HALF THAT GENERALISES. The revision-6 gate
  # enumerated five sites; revision 7 discharged exactly those five and reported "WITHDRAWN at all five
  # sites". THIS SITE WAS NEVER ON THE LIST. The discharge was total over the REPORTED INSTANCES and not
  # over the CLASS — which is verbatim what §14 says five revisions have now done, committed by the
  # revision that wrote §14. §13 now records the class each withdrawal quantifies over and how it was
  # enumerated, because a withdrawal that names a site list is a withdrawal someone can complete without
  # sweeping anything.
  #
  # What this row asserts is NATURALITY IN THE KEY SET, and naturality is APPLIED, not asserted.
  # `scaffoldLeafOfBy` is the scheme; here it is applied at `assertionKeys ++ [ "__extensionProbe" ]`
  # with nothing else changed. The projection moves the probe key across the partition because the
  # key list is its only input; an arm enumerating six names cannot follow, whatever the list says.
  # ★ THE PROBE KEY IS RESERVED-SHAPED ON PURPOSE. A plausible future assertion key (`tolerance`,
  #   say) would make this test go red on the day someone genuinely adds it — for a reason unrelated
  #   to the property. A control whose own name is scheduled for adoption is the defect §3 names for
  #   the per-root controls, one level up.
  # ★ THE TWO `today*` CLAUSES ARE THE POSITIVE CONTROL, in the same assertion: under the SHIPPED
  #   list the identical `out` puts the probe key on the FLEET side. So a green here is the partition
  #   MOVING, not the fixture having been leaf-shaped all along.
  testScaffoldExtendsToANewAssertionKey = {
    expr =
      let
        out = (outOfForm "value") // { __extensionProbe = 1; };
        extended = xfail.assertionKeys ++ [ "__extensionProbe" ];
      in
      {
        extendedLeaf = (xfail.scaffoldLeafOfBy extended out) ? __extensionProbe;
        extendedFleet = (xfail.fleetPartOfBy extended out) ? __extensionProbe;
        todayLeaf = (xfail.scaffoldLeafOf out) ? __extensionProbe;
        todayFleet = (xfail.fleetPartOf out) ? __extensionProbe;
      };
    expected = {
      extendedLeaf = true;
      extendedFleet = false;
      todayLeaf = false;
      todayFleet = true;
    };
  };
  # ★★★ THE SURVIVING NEGATIVE EXISTENTIAL, AS A NUMBER — §9's RULE 3 APPLIED TO THIS DOCUMENT'S OWN
  #     REMAINING CLAIM OF THAT SHAPE RATHER THAN ONLY TO THE ONE THAT WAS REFUTED.
  #
  # "Naturality in the key set is not reachable at one key list" is a negative existential over
  # assertions — the same shape as the sentence revision 7 withdrew, asserted three lines from the
  # withdrawal and left in prose. Rule 3: reduce it to extensional equality of two WRITTEN functions on a
  # DERIVED domain, and state it as a number the battery already computes.
  #   • the two functions are `scaffoldLeafOfBy` and `keyListIgnoringScheme`, both written above;
  #   • the domain is `admissibleOuts` carrying a probe key, so it is derived, not chosen;
  #   • `separatingToday = 0` IS the negative existential — at today's list the two schemes are
  #     extensionally equal, so NO assertion evaluated only there can tell them apart;
  #   • `separatingExtended = 8` is what stops that 0 from being vacuous. A 0 with no non-zero sibling
  #     is indistinguishable from a domain nothing reaches — which is `den-hoag-gg8` at the level of a
  #     claim rather than of a quantifier, and is exactly how M21's kill set of 1 read as a
  #     characterisation when it was a lower bound.
  # ★★★ AND THE 0 IS SHARPER THAN "MEASURED", WHICH STRENGTHENS THE ROW RATHER THAN WEAKENING IT.
  #   `keyListIgnoringScheme _keys out` is DEFINED as `scaffoldLeafOfBy assertionKeys out`, so at
  #   `keys = assertionKeys` the filter's predicate BETA-REDUCES to `x != x`. `separatingToday = 0` is
  #   therefore DEFINITIONALLY FORCED — it holds on any domain whatever, INCLUDING THE EMPTY ONE, and it
  #   would hold if `naturalityDomain` were `[ ]` and every other clause here were broken.
  # ⇒ The 0 carries NO evidential weight on its own; `separatingExtended = 8` carries all of it, and
  #   `domainSize = 8` is what stops the 8 from being read without a denominator. That is not a defect in
  #   the row: it is precisely WHY the sibling had to exist, and it is Rule 3's own content restated at
  #   the row that instantiates Rule 3. A negative existential reduced to a number is only as good as the
  #   number's ability to have come out otherwise — and this one could not have.
  # ★ AND NOTE WHICH FOIL THIS IS. M21 cannot witness this property: it rebuilds per arm as well as
  #   ignoring the list, so it IS separable at one key list — which is the whole of revision 7's
  #   correction, one level down. A foil for a naturality claim must differ from the scheme in the key
  #   list ALONE.
  testNaturalityUnreachableAtOneKeyListAsANumber = {
    expr = {
      domainSize = builtins.length naturalityDomain;
      separatingToday = builtins.length (naturalitySeparatingAt xfail.assertionKeys);
      separatingExtended = builtins.length (naturalitySeparatingAt naturalityExtended);
    };
    expected = {
      domainSize = 8;
      separatingToday = 0;
      separatingExtended = 8;
    };
  };
  # ★ THE FIXTURE'S OWN TOTALITY, ASSERTED — this is what makes "the key enters the fixture" the
  #   only alternative to a named failure, and it is asserted on BOTH arms of that disjunction.
  testFixtureSampleIsTotalOverAssertionKeys = {
    expr = builtins.all (k: builtins.hasAttr k sampleValues) xfail.assertionKeys;
    expected = true;
  };
  # ★ the probe key is reserved-shaped for the same reason the extension probe is: a control named after
  #   a plausible future assertion key goes red the day someone adopts it, for a reason unrelated to the
  #   arm it asserts.
  testFixtureSampleRefusesAnUnvaluedKey = {
    expr = sampleOf "__unvaluedProbe";
    expectedError = { type = "ThrownError"; msg = "has no entry for it"; };
  };
  # ★★ ...AND THE ONE LINE THAT MAKES THAT REFUSAL REACHABLE IN THE SCENARIO IT IS WRITTEN FOR RATHER
  #    THAN ONLY BY THE DIRECT CALL ABOVE. On revision 6 the row above was green while a seventh
  #    unvalued key produced ZERO occurrences of its message: `listToAttrs` binds lazily and no
  #    consumer forces a value, so the three rows died on a cardinality clause. The claim was about
  #    `sampleOf`; the scenario ran through `outOfForm`; the two were never connected.
  testFixtureForcingReachesTheNamedRefusal = {
    expr = forceValues { valued = 1; unvalued = sampleOf "__unvaluedProbe"; };
    expectedError = { type = "ThrownError"; msg = "has no entry for it"; };
  };
  # ★ ...with its positive control in the same run: forcing is TRANSPARENT when every value is present,
  #   so the row above is the throw being reached, not `forceValues` refusing everything.
  testFixtureForcingIsTransparent = {
    expr = forceValues { a = 1; b = "two"; };
    expected = { a = 1; b = "two"; };
  };
  # ★ THE TWO DECLARED SUB-LISTS ARE ACTUALLY SUB-LISTS. §6b calls `attributionKeys ⊂ assertionKeys`
  #   "the checked pair" and revision 6 checked it nowhere — the binding was declared and then used by
  #   nothing, which is `den-hoag-gg8`'s shape at the level of a definition rather than a quantifier.
  #   `formKeys` arrives with the same obligation, so both are asserted here, disjoint and covering
  #   the two acts §6b distinguishes: carriage-as-one-decision, and dispatch.
  testDeclaredKeySublistsAreSubsetsOfAssertionKeys = {
    expr = {
      attribution = builtins.all (k: elem k xfail.assertionKeys) xfail.attributionKeys;
      form = builtins.all (k: elem k xfail.assertionKeys) xfail.formKeys;
      disjoint = builtins.filter (k: elem k xfail.formKeys) xfail.attributionKeys;
    };
    expected = { attribution = true; form = true; disjoint = [ ]; };
  };
  # ★★ THE SCHEME'S DOMAIN, ASSERTED AT BOTH ENDS OF THE DISJUNCTION. A `keys` missing either form key
  #    is a NAMED refusal rather than the uncaught missing-attribute EvalError revision 6 left there.
  #    Revision 6 asserted naturality "whatever the list says" and applied the scheme at two lists,
  #    both ⊇ `assertionKeys`; a universal over lists does not get to leave its domain undeclared.
  testSchemeRefusesAKeyListWithoutExpected = {
    expr = xfail.scaffoldLeafOfBy [ "bead" "construct" "expectedError" "expr" ] (outOfForm "error");
    expectedError = { type = "ThrownError"; msg = "omits a FORM key"; };
  };
  testSchemeRefusesAKeyListWithoutExpectedError = {
    expr = xfail.scaffoldLeafOfBy [ "bead" "construct" "expected" "expr" ] (outOfForm "value");
    expectedError = { type = "ThrownError"; msg = "omits a FORM key"; };
  };
  # ★ POSITIVE CONTROL, same run: a SHORTER list that still contains both form keys is admitted, so the
  #   refusal is the domain condition and not "any list but the shipped one".
  testSchemeAdmitsAnyListContainingBothFormKeys = {
    expr = builtins.attrNames (
      xfail.scaffoldLeafOfBy [ "expected" "expectedError" "expr" ] (outOfForm "value")
    );
    expected = [ "expected" "expr" ];
  };
  # ★★ ...and the fourth case of the scaffold's own dispatch, which was the same EvalError at the OTHER
  #    argument: an `out` declaring neither form key. nix-unit cannot run such a leaf either way; the
  #    difference is whether the author is told why.
  testScaffoldRefusesNeitherAssertionForm = {
    expr = denTestLeaf { expr = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; };
    expectedError = { type = "ThrownError"; msg = "declares NEITHER"; };
  };
  # ★★★ THE r4 DEFECT, AS A REGRESSION TEST. r4 replaced the scaffold's ERROR arm and left the
  #     VALUE arm building from a fixed key set — and ALL SIX of §6's declarations are value-form.
  #     Measured on r4: `[bead construct expected expr]` in, `[expected expr]` out, census `[ ]`,
  #     leaf GREEN. Attribution is now applied above the arm dispatch, so BOTH value branches keep
  #     it: the scalar branch here, the `intersectAttrs` branch below.
  testScaffoldValueArmKeepsAttribution = {
    expr = builtins.attrNames (denTestLeaf { expr = 0; expected = 0; bead = "den-hoag-gb9"; construct = "pipeOps"; });
    expected = [ "bead" "construct" "expected" "expr" ];
  };
  testScaffoldValuePartialMatchArmKeepsAttribution = {
    expr = builtins.attrNames (
      denTestLeaf { expr = { a = 1; b = 2; }; expected = { a = 9; }; bead = "den-hoag-gb9"; construct = "pipeOps"; }
    );
    expected = [ "bead" "construct" "expected" "expr" ];
  };
  # ...and the partial match still HAPPENS — the arm's own semantics is untouched by the hoist.
  testScaffoldPartialMatchStillIntersects = {
    expr = (denTestLeaf { expr = { a = 1; b = 2; }; expected = { a = 9; }; bead = "den-hoag-gb9"; construct = "pipeOps"; }).expr;
    expected = { a = 1; };
  };
  # ★ AND THE CENSUS SEES IT — the end-to-end statement, which is what `[ ]` hid on r4.
  testScaffoldValueArmCensusesCorrectly = {
    expr = censusOf {
      a = { test-one = denTestLeaf { expr = 0; expected = 0; correct = 3; bead = "den-hoag-gb9"; construct = "pipeOps"; }; };
    };
    expected = [ { id = "a.test-one"; bead = "den-hoag-gb9"; construct = "pipeOps"; sites = [ "lib/concern-policies.nix" ]; } ];
  };
  # ★ `correct` rides through the scaffold too — which is what makes the census's degenerate
  #   re-check REACHABLE for a scaffold-hosted declaration rather than only for a direct one.
  testScaffoldValueArmForwardsCorrect = {
    expr = (denTestLeaf { expr = 0; expected = 0; correct = 3; bead = "den-hoag-gb9"; construct = "pipeOps"; }).correct;
    expected = 3;
  };
  # ...and the end-to-end statement: a DEGENERATE declaration authored through the scaffold is
  # refused at the census. Both halves — the forwarding and the re-check — are needed for this row.
  testScaffoldValueArmDegenerateCaughtByCensus = {
    expr = censusOf {
      a = { test-one = denTestLeaf { expr = 1; expected = 1; correct = 1; bead = "den-hoag-gb9"; construct = "pipeOps"; }; };
    };
    expectedError = { type = "ThrownError"; msg = "degenerate xfail"; };
  };
  testScaffoldForwardsAttributionWhenPresent = {
    expr = (denTestLeaf { expr = 1; expectedError = { type = "ThrownError"; msg = "b"; }; bead = "den-hoag-9xo.75"; construct = "recoverEmits"; }).bead;
    expected = "den-hoag-9xo.75";
  };
  testScaffoldOmitsAttributionWhenAbsent = {
    expr = builtins.attrNames (denTestLeaf { expr = 1; expectedError = { type = "ThrownError"; msg = "b"; }; });
    expected = [ "expectedError" "expr" ];
  };
  testScaffoldOmitsAttributionWhenAbsentOnValueArm = {
    expr = builtins.attrNames (denTestLeaf { expr = 1; expected = 2; });
    expected = [ "expected" "expr" ];
  };
  # ★ THE THIRD ENFORCEMENT POINT — the scaffold forwards attribution, so it checks attribution.
  #   Without this, a scaffold-hosted test is a supported way to author the leaf the constructor
  #   refuses, one file away from the guard that refuses it. Checked on BOTH arms, because the
  #   check is above the dispatch and an arm-shaped check is what r4 shipped.
  testScaffoldChecksForwardedBead = {
    expr = denTestLeaf { expr = 1; expectedError = { type = "ThrownError"; msg = "b"; }; bead = "TODO"; construct = "recoverEmits"; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  testScaffoldChecksForwardedConstruct = {
    expr = denTestLeaf { expr = 1; expectedError = { type = "ThrownError"; msg = "b"; }; bead = "den-hoag-9xo.75"; construct = "empty codomain"; };
    expectedError = { type = "ThrownError"; msg = "not bound in the governed source"; };
  };
  testScaffoldChecksForwardedBeadOnValueArm = {
    expr = denTestLeaf { expr = 0; expected = 0; bead = "TODO"; construct = "recoverEmits"; };
    expectedError = { type = "ThrownError"; msg = "not a den-hoag tracker id"; };
  };
  testScaffoldChecksForwardedConstructOnValueArm = {
    expr = denTestLeaf { expr = 0; expected = 0; bead = "den-hoag-9xo.75"; construct = "empty codomain"; };
    expectedError = { type = "ThrownError"; msg = "not bound in the governed source"; };
  };
  testScaffoldRefusesPartialAttribution = {
    expr = denTestLeaf { expr = 1; expectedError = { type = "ThrownError"; msg = "b"; }; bead = "den-hoag-9xo.75"; };
    expectedError = { type = "ThrownError"; msg = "attribution is PARTIAL"; };
  };
  testScaffoldRefusesPartialAttributionOnValueArm = {
    expr = denTestLeaf { expr = 0; expected = 0; construct = "recoverEmits"; };
    expectedError = { type = "ThrownError"; msg = "attribution is PARTIAL"; };
  };
  # the strip list is a SUPERSET of every key either arm can emit — the property that keeps
  # assertion keys off the flake-parts module face.
  testStripListCoversBothArms = {
    expr = builtins.all (k: elem k xfail.assertionKeys) (
      builtins.attrNames (xfail.value { bead = "den-hoag-gb9"; construct = "pipeOps"; expr = 0; actual = 0; correct = 3; })
      ++ builtins.attrNames (denTestLeaf { expr = 1; expectedError = { type = "T"; msg = "b"; }; bead = "den-hoag-gb9"; construct = "pipeOps"; })
      ++ builtins.attrNames (denTestLeaf { expr = 0; expected = 0; correct = 3; bead = "den-hoag-gb9"; construct = "pipeOps"; })
    );
    expected = true;
  };
}
