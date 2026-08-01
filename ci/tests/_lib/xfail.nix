# DECLARED KNOWN-FAILURES — a red carries its own attribution, in the tree, as the test.
#
# A suite whose gate is one boolean cannot distinguish "a new failure", "a known failure still
# failing" and "a known failure that started passing". The construction here gives a known failure a
# SECOND REPRESENTATION: a declaration that names the tracker id and the SOURCE BINDING whose
# retirement makes the claim false. The declaration IS the test, so there is no second artifact to
# keep in step with the first and nothing parses the runner's output.
#
# Three verdicts fall out of nix-unit's own two assertion channels, with no arithmetic over markers:
#   declared, still failing the declared way  → green (`expected` IS the observed-wrong value)
#   declared, now passing                     → red   (the observed value moved off `expected`)
#   declared, failing differently             → red   (a value form that starts throwing goes ☢️;
#                                                      an error form whose `type`/`msg` moves goes ❌)
#   undeclared red                            → red, unchanged
#
# THE OPT-IN LIMIT IS REAL AND IS NOT CLOSED HERE. Nothing compels a red to become a declaration: an
# author may edit `expected` in place to the observed-wrong value, and the census below is
# byte-identical either way. That is a diff-review property, not a mechanism property.
#
# APPLY THIS ONCE, AT THE FLAKE, AND THREAD THE RESULT. `import` memoises the lambda, not the
# application, so importing-and-applying per declaring file rebuilds the anchor index once per file.
# Applied once, the index is one thunk per evaluation however many leaves are declared.
{ denHoagSrc }:
rec {
  # ── prelude ───────────────────────────────────────────────────────────────────────────────────
  # `hasInfix` is built from `splitString`, never a `.*needle.*` regex over whole-file input: the
  # regex form overflows the C stack on inputs this size.
  escapeRE =
    s:
    builtins.replaceStrings
      [
        "."
        "*"
        "+"
        "?"
        "["
        "]"
        "("
        ")"
        "^"
        "$"
        "\\"
        "|"
        "{"
        "}"
      ]
      [
        "\\."
        "\\*"
        "\\+"
        "\\?"
        "\\["
        "\\]"
        "\\("
        "\\)"
        "\\^"
        "\\$"
        "\\\\"
        "\\|"
        "\\{"
        "\\}"
      ]
      s;
  splitOn = sep: s: builtins.filter builtins.isString (builtins.split (escapeRE sep) s);
  hasInfix = needle: hay: builtins.length (splitOn needle hay) > 1;
  countOcc = needle: s: builtins.length (splitOn needle s) - 1;
  elem = builtins.elem;
  uniqSort =
    xs:
    builtins.sort (a: b: a < b) (
      builtins.attrNames (
        builtins.listToAttrs (
          map (x: {
            name = x;
            value = 1;
          }) xs
        )
      )
    );

  # ── G1: the tracker id's SHAPE ────────────────────────────────────────────────────────────────
  # `builtins.match` is a FULL match, so the pattern is anchored by construction and prose
  # placeholders are rejected. It does NOT check that a well-formed id EXISTS or is OPEN — neither is
  # decidable in a pure eval, and both are deliberately left to a reviewer.
  beadShapeOk = b: builtins.isString b && builtins.match "den-hoag-[0-9a-z]{3}(\\.[0-9]+)*" b != null;

  # ── the `msg` floor, as a PREDICATE so the census can re-check it ─────────────────────────────
  # nix-unit matches `msg` as a regex with SEARCH semantics, so a pattern matches EVERY message iff it
  # can match the empty substring — which every string contains. That is an exact characterisation
  # rather than a heuristic. It does not reject `"."`; nothing in a pure eval can.
  msgIsTotal = m: builtins.isString m && builtins.match m "" != null;

  # ── G3: the anchor index, DERIVED FROM SOURCE ─────────────────────────────────────────────────
  #
  # `construct` is not tested for OCCURRENCE in file text. An occurrence test admits comments and
  # prose, and — the property that matters — SURVIVES the retirement it exists to witness: a deleted
  # binding whose explanatory comment stays behind still "occurs". It is tested for MEMBERSHIP in the
  # set of identifiers the governed source BINDS, so deleting the binding invalidates the claim.
  #
  # THE EXTRACTOR IS NOT A NIX LEXER AND DOES NOT PRETEND TO BE. It is a per-line `builtins.match`
  # carrying exactly ONE bit of lexical state: whether the line sits inside an indented (`''`) string.
  # Without that bit, names that are binding-shaped only inside usage documentation enter the index
  # and anchor claims to text that binds nothing.
  #
  # Two escape forms must be removed BEFORE the `''` delimiters are counted, or the bit inverts and
  # stays inverted for the rest of the file: `''${` (an escaped interpolation — one `''` on a line
  # that is INSIDE a string) and `'''` (an escaped `''`).
  #
  # A `#`-comment tail is stripped before counting but NOT before matching, so a `''` mentioned in a
  # comment cannot flip the bit while a `#` line still cannot produce a binding. KNOWN LIMIT: on a
  # line that opens AND closes a `''` string and then carries a `#`, the strip deletes the closing
  # delimiter and the bit inverts and stays inverted. Zero instances in the governed roots.
  #
  # `/* */` is deliberately not tracked: there are zero block comments in the governed roots, and the
  # naive tracker is measurably worse — testing for `/*` before stripping the `#` tail reads a glob in
  # a comment as an opener and swallows the rest of the file.
  bindingPat = "[[:space:]]*([a-zA-Z_][a-zA-Z0-9_'.-]*)[[:space:]]*=([^=].*|)"; # `=`, not `==`
  linesOf = t: builtins.filter builtins.isString (builtins.split "\n" t);
  namesOfLine =
    l:
    let
      m = builtins.match bindingPat l;
    in
    if m == null then
      [ ]
    else
      let
        p = builtins.head m;
        comps = builtins.filter builtins.isString (builtins.split "\\." p);
      in
      if builtins.length comps <= 1 then
        [ p ]
      else
        [
          p
          (builtins.elemAt comps (builtins.length comps - 1))
        ];
  stripHashTail =
    l:
    let
      m = builtins.match "([^#]*)#.*" l;
    in
    if m == null then l else builtins.head m;
  deEscape =
    s:
    builtins.replaceStrings
      [
        "''\${"
        "'''"
      ]
      [
        ""
        ""
      ]
      s;
  odd = n: builtins.bitAnd n 1 == 1;
  stepLine =
    st: l:
    if st.inStr then
      # inside a `''` string: contribute NOTHING, and close on an odd delimiter count.
      (if odd (countOcc "''" (deEscape l)) then st // { inStr = false; } else st)
    else
      {
        inStr = odd (countOcc "''" (deEscape (stripHashTail l)));
        out = st.out ++ namesOfLine l;
      };
  namesIn =
    t:
    (builtins.foldl' stepLine {
      inStr = false;
      out = [ ];
    } (linesOf t)).out;

  isNix = n: builtins.match ".*\\.nix" n != null;

  # THE GOVERNED ROOTS. `construct` means "the binding whose deletion makes this claim false". For a
  # claim about the fleet that binding is in `lib/`; for a claim about the harness it is in the
  # harness — which is why the harness lib is a root rather than an exception.
  anchorRoots = [
    {
      name = "core";
      dir = "lib";
      prefix = "lib/";
      skipDirs = [ "compat" ];
    }
    {
      name = "compat";
      dir = "lib/compat";
      prefix = "lib/compat/";
      skipDirs = [ ];
    }
    {
      name = "harness";
      dir = "ci/tests/_lib";
      prefix = "ci/tests/_lib/";
      skipDirs = [ ];
    }
  ];
  filesOfRoot =
    r:
    let
      base = "${denHoagSrc}/${r.dir}";
      walk =
        rel:
        let
          e = builtins.readDir "${base}/${rel}";
        in
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

  # THE HAYSTACK CONTROL, and it is a PROJECTION OF THE INDEX'S OWN FILE LIST rather than a second
  # walk. A control derived from a separate traversal would be sound for a different proposition than
  # the one it is asked to prove — per-root controls naming one top-level binding each stay green
  # while a non-recursive walk silently drops every subdirectory. `contributingDirs` cannot: it IS
  # `filesOfRoot`, mapped to directories, so a walk that stops descending loses the directories from
  # the very list the index is built from.
  dirOfRel =
    f:
    let
      comps = builtins.filter builtins.isString (builtins.split "/" f);
    in
    if builtins.length comps <= 1 then
      ""
    else
      builtins.concatStringsSep "/" (
        builtins.genList (i: builtins.elemAt comps i) (builtins.length comps - 1)
      )
      + "/";
  contributingDirs = r: uniqSort (map dirOfRel (filesOfRoot r));

  pairsOfRoot =
    r:
    builtins.concatMap (
      f:
      map (n: {
        name = n;
        file = "${r.prefix}${f}";
      }) (namesIn (builtins.readFile "${denHoagSrc}/${r.dir}/${f}"))
    ) (filesOfRoot r);
  anchorPairs = builtins.concatMap pairsOfRoot anchorRoots;
  # name → the files that BIND it. Not a boolean: a PARTIAL retirement (one of N definitions deleted)
  # moves `sites` while membership survives, and the census row then changes under review.
  sitesOf = n: uniqSort (map (p: p.file) (builtins.filter (p: p.name == n) anchorPairs));
  anchorResolves = c: builtins.isString c && sitesOf c != [ ];

  # ── the two leaf forms, WITH G1 AND G3 APPLIED BY THE CONSTRUCTOR ─────────────────────────────
  #
  # There is no path from an author's keystrokes to a declared leaf that does not pass through
  # `checkedAttribution`: it is not a guard leaf someone remembers to write, it is the first thing
  # every producer forces. `builtins.seq` is load-bearing and its effect is to FIX THE DIAGNOSIS
  # ORDER to attribution-first — without it the form-specific clause is the `if` condition and
  # therefore always evaluates first, so an author whose bead names nothing is told their `msg` is too
  # broad instead.
  #
  # The clauses are `throw`s rather than `assert`s because an `assert` renders as "a list of value
  # '[ ]' is not equal to null of value 'null'", which tells an author nothing.
  checkedAttribution =
    form: bead: construct:
    if !(beadShapeOk bead) then
      throw "xfail.${form}: `bead` is not a den-hoag tracker id — G1 rejects it. A declaration whose bead does not match `den-hoag-[0-9a-z]{3}(.N)*` attributes the known-fail to nothing"
    else if !(anchorResolves construct) then
      throw "xfail.${form}: `construct` is not bound in the governed source — G3 rejects it. `construct` must be an identifier the kernel BINDS, so that retiring it invalidates this declaration; a prose phrase or a comment cannot name a binding"
    else
      { inherit bead construct; };

  # EVERY FIELD IS REQUIRED AND TOTAL. There are no defaults in either form, and that is the whole of
  # the decision: nix-unit reads an omitted `type` as ANY KIND and an omitted `msg` as ANY MESSAGE, so
  # a default would write a fail-open into the one axis the mechanism exists to exploit.
  xfailError =
    {
      bead,
      construct,
      expr,
      type,
      msg,
    }:
    let
      att = checkedAttribution "error" bead construct;
    in
    builtins.seq att (
      if msgIsTotal msg then
        throw "xfail.error: `msg` matches EVERY message (it matches the empty string, and nix-unit matches `msg` as a search) — such a pattern asserts nothing about the failure"
      else
        att
        // {
          inherit expr;
          expectedError = { inherit type msg; };
        }
    );

  # `correct` RIDES ON THE LEAF rather than being discarded after the degenerate check. From
  # `expected` alone nothing downstream can tell whether the claim is degenerate, so the census — the
  # only TOTAL enforcement point — could not re-check the one clause `expected` is derived from.
  # nix-unit tolerates the extra key, so the leaf carries the WHOLE claim and the census re-checks it.
  xfailValue =
    {
      bead,
      construct,
      expr,
      actual,
      correct,
    }:
    let
      att = checkedAttribution "value" bead construct;
    in
    builtins.seq att (
      if actual == correct then
        throw "xfail.value: `actual` equals `correct` — a degenerate xfail claims today's value is also the right one"
      else
        att
        // {
          inherit expr correct;
          expected = actual;
        }
    );

  error = xfailError;
  value = xfailValue;

  # ── the leaf/fleet partition, AS A SCHEME IN THE KEY LIST ─────────────────────────────────────
  #
  # `assertionKeys` partitions a scaffold's `out` EXACTLY: the leaf is `out` projected onto it, and
  # the flake-parts module face is the complement. Both uses are DERIVED from this one list.
  #
  # THE LEAF IS A PROJECTION, NOT A REBUILD. A dispatch whose arms each construct a fresh literal
  # attrset from a fixed key set silently DROPS every field it does not name, and each arm's list
  # drifts independently of the other's — which is how the same erasure gets found twice from two
  # directions. Under a projection no arm names any key, so a key added here rides through every arm
  # with no edit anywhere.
  assertionKeys = [
    "bead"
    "construct"
    "correct"
    "expected"
    "expectedError"
    "expr"
  ];
  setOf =
    ks:
    builtins.listToAttrs (
      map (k: {
        name = k;
        value = null;
      }) ks
    );
  assertionKeySet = setOf assertionKeys;
  # ⊂ assertionKeys. Attribution is ONE decision, not two — so the check QUANTIFIES over this list
  # rather than reading two hand-written booleans, and "all of it or none of it" is the shape of the
  # check rather than a coincidence of how two `?`s were combined.
  attributionKeys = [
    "bead"
    "construct"
  ];
  # ⊂ assertionKeys. The DISPATCH pair — the keys the scaffold reads to decide WHICH FORM a leaf is,
  # as opposed to the keys it CARRIES. Naming a key to DECIDE a form is bounded by the number of
  # forms; naming a key to CARRY it is bounded by nothing. This is also the scheme's DOMAIN.
  formKeys = [
    "expected"
    "expectedError"
  ];

  # A pure GUARD rather than a producer: the data is already on the leaf by projection, so the check
  # does not reconstruct it. Coupling check with construction is what lets a fix be arm-shaped.
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

  # THE SCHEME'S DOMAIN IS DECLARED AT BOTH ARGUMENTS. A universal asserted at two instances still
  # has a domain: at a `keys` omitting a form key the dispatch would read an attribute the projection
  # could not have carried — a missing-attribute EvalError that `tryEval` cannot catch and that
  # surfaces as an unexplained ☢️. Both partial cases are named refusals instead.
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
          # A leaf carrying BOTH keys is ☢️ when `expr` throws and ✅ GREEN WITH `expectedError`
          # SILENTLY IGNORED when it does not — nix-unit runs it as a value-form test either way, and
          # only the throwing case is loud. This refusal therefore covers two outcomes, and the QUIET
          # one is the dangerous one.
          (
            if leaf ? expected then
              throw "xfail.scaffold: the leaf declares BOTH `expected` and `expectedError` — the two forms are disjoint, and nix-unit reports such a leaf as ☢️ with the throw escaping uncaught"
            else
              leaf
          )
        else if !(leaf ? expected) then
          throw "xfail.scaffold: the leaf declares NEITHER `expected` nor `expectedError` — a leaf with no assertion form is not a test, and reading the absent key is an EvalError `tryEval` cannot catch"
        # PARTIAL MATCHING: compare only the keys `expected` names when both are attrsets. THE ONLY
        # TRANSFORMATION THE SCAFFOLD PERFORMS, written as an override of the single key it changes.
        else if builtins.isAttrs leaf.expected && builtins.isAttrs leaf.expr then
          leaf // { expr = builtins.intersectAttrs leaf.expected leaf.expr; }
        else
          leaf
      );
  fleetPartOfBy = keys: out: builtins.removeAttrs out keys;
  # The shipped pair is the scheme applied at the shipped list — ONE application, written once, so the
  # two faces cannot be specialised at different lists.
  scaffoldLeafOf = scaffoldLeafOfBy assertionKeys;
  fleetPartOf = fleetPartOfBy assertionKeys;

  # ── G2: the census, and THE TOTAL ENFORCEMENT POINT ───────────────────────────────────────────
  #
  # `censusOf` walks `attrNames` and selects leaves carrying either half of the attribution pair.
  # Because that selection IS the definition of "a declared xfail", checking here makes the guards
  # total over the tree: a leaf written by hand, never touching a constructor, is still a row and is
  # still checked. The constructor makes a bad leaf unbuildable on the sanctioned path; the census
  # makes it unreachable on EVERY path. Neither alone is total.
  #
  # WHAT IT RE-CHECKS is derived from the constructor text above, not from a prose list — a
  # by-construction clause is exactly one of three things, each readable off the code: a field in a
  # non-`...` destructuring pattern (required-ness), an `if … then throw` (a value clause), or a key
  # a non-`...` pattern REFUSES (disjointness).
  #
  # WHAT IT CANNOT CHECK: that the bead EXISTS and is OPEN (not decidable in a pure eval), and that
  # `expr` really produces `expected` — that is nix-unit's job, and it is what makes the three
  # verdicts work.
  censusRow =
    id: l:
    # Half-attribution is refused in BOTH directions. Selecting on `? bead` alone would make the
    # census total over one half of a decision that is indivisible: a hand-written leaf carrying
    # `construct` without `bead` would never be a row at all.
    if !(l ? bead) then
      throw "G2 census: leaf `${id}` carries `construct` without `bead` — attribution is one decision, not two, and the half that names the tracker id is the half that is missing"
    else if !(l ? construct) then
      throw "G2 census: leaf `${id}` carries `bead` without `construct` — attribution is one decision, not two"
    else if !(beadShapeOk l.bead) then
      throw "G2 census: leaf `${id}` has a `bead` that G1 rejects — it attributes the known-fail to nothing"
    else if !(anchorResolves l.construct) then
      throw "G2 census: leaf `${id}` names a `construct` that is not bound in the governed source — G3 rejects it"
    # `expr` is required on BOTH forms, so it is checked ABOVE the form dispatch. A leaf with no
    # `expr` censuses clean as a four-key value row while ☢️-ing at the instrument.
    else if !(l ? expr) then
      throw "G2 census: leaf `${id}` carries no `expr` — a declared xfail with nothing to evaluate is not a test, and nix-unit reports the omission as an unnamed ☢️ rather than as a missing declaration"
    # THIS CLAUSE MUST PRECEDE THE FORM DISPATCH — THE DISPATCH IS WHAT HIDES IT. Dispatching on
    # `? expectedError` first routes a value-form leaf carrying one well-formed `expectedError` down
    # the error arm, skipping every remaining value clause; and the admitted row is `==` to the row a
    # LEGITIMATE error leaf produces, so a reviewer diffing the census cannot tell the two apart.
    # The harm is asymmetric and both directions are refused: `expected` alongside `expectedError` is
    # the fail-open (nix-unit switches form); `correct` alongside it is a half-written claim wearing
    # keys of two forms.
    else if l ? expectedError && (l ? expected || l ? correct) then
      throw "G2 census: leaf `${id}` carries `expectedError` alongside a VALUE-form key (`expected` or `correct`) — the two forms are disjoint, and nix-unit runs such a leaf as a value-form test with `expectedError` silently ignored"
    else if l ? expectedError then
      (
        # Absence is a decision on the error form too. `type` absent is the strictly worse case: the
        # row is built with `inherit`, which binds lazily, so the census returns a STRUCTURALLY
        # COMPLETE row with the error as a thunk that surfaces only under deep force.
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
    # A value-form declaration must carry the WHOLE claim or the degenerate clause is unobservable
    # from the leaf. `expected` is required for the same reason `correct` is: without it the next
    # clause reads `l.expected` off a leaf that has none, which is an EvalError `tryEval` cannot
    # catch — the very error class these clauses exist to convert into named refusals.
    else if !(l ? expected) then
      throw "G2 census: leaf `${id}` is a value-form declared xfail without `expected` — the claim `today it is X` is missing its X, and reading the absent key is an EvalError `tryEval` cannot catch"
    else if !(l ? correct) then
      throw "G2 census: leaf `${id}` is a value-form declared xfail without `correct` — the claim `today it is X, it should be Y` is half-written, and the degenerate case cannot be seen"
    else if l.expected == l.correct then
      throw "G2 census: leaf `${id}` is a degenerate xfail — `expected` equals `correct`, so it claims today's value is also the right one"
    else
      {
        inherit id;
        inherit (l) bead construct;
        sites = sitesOf l.construct;
      };
  censusOf =
    tests:
    builtins.sort (a: b: a.id < b.id) (
      builtins.concatMap (
        s:
        builtins.concatMap (
          n:
          let
            l = tests.${s}.${n};
          in
          if l ? bead || l ? construct then [ (censusRow "${s}.${n}" l) ] else [ ]
        ) (builtins.attrNames tests.${s})
      ) (builtins.attrNames tests)
    );

  # ── suite completeness, over `attrNames` ONLY ─────────────────────────────────────────────────
  #
  # A TOTAL-COUNT ASSERTION IS REJECTED. It is a repair-shaped invariant: it must be re-applied on
  # every added test, it turns the good act of adding a test into a gate failure, and a count cannot
  # see a green-but-vacuous leaf anyway. These assert STRUCTURAL COMPLETENESS instead.
  #
  # (1)-(3) are MONOTONE: adding a test can never break them, emptying a suite always does. No list is
  # involved, so none can go stale. NO LEAF BODY IS FORCED — a completeness guard that forced test
  # bodies would evaluate the fleet once per declaring file.
  emptySuites = tests: builtins.filter (s: tests.${s} == { }) (builtins.attrNames tests);
  # nix-unit detects tests by a `test` prefix; a leaf without one is SILENTLY NOT RUN, and the
  # printed denominator does not count it either.
  badPrefixLeaves =
    tests:
    builtins.concatMap (
      s:
      map (n: "${s}.${n}") (
        builtins.filter (n: builtins.match "test.*" n == null) (builtins.attrNames tests.${s})
      )
    ) (builtins.attrNames tests);
  nestedLeaves =
    tests:
    builtins.concatMap (
      s:
      map (n: "${s}.${n}") (
        builtins.filter (
          n:
          let
            v = tests.${s}.${n};
          in
          builtins.isAttrs v && !(v ? expr)
        ) (builtins.attrNames tests.${s})
      )
    ) (builtins.attrNames tests);
  # (4) THE FILE CENSUS, and it is REQUIRED rather than optional. Several suites are declared across
  # more than one file; for those, (1) does not see a whole file's contribution disappear, because the
  # suite stays non-empty via its siblings. (4) is the only guard that sees the file go — it is the
  # multi-file half of the emptiness property, not bookkeeping.
  #
  # The exclusion is the repo's OWN convention rather than a hand-kept list: a `_`-prefixed directory
  # is what import-tree/mkCi already skip as a flake-parts module. Naming one such directory by hand
  # mis-counts by however many others exist.
  actualTestFiles =
    let
      base = "${denHoagSrc}/ci/tests";
      walk =
        rel:
        let
          e = builtins.readDir "${base}/${rel}";
        in
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
}
