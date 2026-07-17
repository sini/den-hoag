# The explicit algebraic-law harness (spec §5, the disciplines laws ladder). den.disciplines DECLARES
# the algebra each merge site obeys; this suite SAMPLES that declaration — it evaluates the ladder laws
# over each discipline's `{ empty; combine }` on a small finite sample set, turning the implicit "the
# fold is a monoid" assumption into an explicit, teeth-bearing check. The laws (theory anchors, cited
# not restated): a MONOID is associativity + a two-sided identity; a COMMUTATIVE monoid adds
# commutativity; a JOIN-SEMILATTICE adds idempotence (Shapiro et al.'s CRDT ACI convergence — the
# property Arntzenius & Krishnaswami's Datafun requires of a fixpoint's carrier); SHADOW is Leijen's
# scoped-label last-wins record merge (right-absorption on overlapping keys), off the monoid ladder.
#
# The harness is TEST MACHINERY (the sampler lives here, not in lib/ — the kernel declares algebras, it
# does not sample them). It ITERATES the compiled `den.disciplines` table, so every registered
# discipline (the framework instances landing in later steps included) is covered automatically; the
# per-discipline sample sets are declared beside the fixtures that exercise them.
#
# SAMPLES are structural values only (lists / attrsets / strings) compared by `==` — a function-valued
# sample has undecidable equality, so `combine`'s laws are sampled on the DATA it folds, never on
# functions.
{
  denHoag,
  ...
}:
let
  inherit (denHoag.internal) compileDisciplines;

  # ── the sampler ─────────────────────────────────────────────────────────────────────────────────
  # `checkLaws { name; laws; empty; combine; samples }` evaluates the ladder laws for `laws` over the
  # finite `samples` (≥3 values, INCLUDING `empty` and a duplicated element — the caller supplies them).
  # It THROWS a named `den.disciplines: '<name>' violates <law>` on the FIRST violated law, else returns
  # true — so a lawful instance passes and an unlawful one is caught LOUD by a `tryEval` (the teeth).
  #
  # Each ladder class checks its own law AND every weaker law it subsumes (a join-semilattice is checked
  # for associativity + identity + commutativity + idempotence). `shadow` is off the monoid ladder — it
  # checks right-absorption alone (last-wins on overlapping keys).
  checkLaws =
    {
      name,
      laws,
      empty,
      combine,
      samples,
    }:
    let
      violate = law: throw "den.disciplines: '${name}' violates ${law}";
      # all ordered (a, b) and (a, b, c) tuples over the sample set — a finite, exhaustive sweep.
      pairs = builtins.concatMap (a: map (b: { inherit a b; }) samples) samples;
      triples = builtins.concatMap (
        a: builtins.concatMap (b: map (c: { inherit a b c; }) samples) samples
      ) samples;

      # associativity: (a·b)·c == a·(b·c) over every triple.
      assoc = builtins.all (t: combine (combine t.a t.b) t.c == combine t.a (combine t.b t.c)) triples;
      # two-sided identity: empty·x == x == x·empty over every sample.
      identity = builtins.all (x: combine empty x == x && combine x empty == x) samples;
      # commutativity: a·b == b·a over every pair.
      commutative = builtins.all (p: combine p.a p.b == combine p.b p.a) pairs;
      # idempotence: x·x == x over every sample.
      idempotent = builtins.all (x: combine x x == x) samples;
      # right-absorption (Leijen last-wins): a·b == b on OVERLAPPING keys — sampled with attrset values,
      # so `combine a b` at a shared key yields b's value. The samples for a shadow instance overlap by
      # construction; the check is `combine a b == b` where a and b share their whole key set.
      absorbing = builtins.all (p: combine p.a p.b == p.b) pairs;

      # the ladder: each class asserts its law and all weaker ones (subsumption). shadow stands apart.
      monoid =
        (if assoc then true else violate "associativity")
        && (if identity then true else violate "identity");
      comm = monoid && (if commutative then true else violate "commutativity");
      semilattice = comm && (if idempotent then true else violate "idempotence");
    in
    if laws == "ordered-monoid" then
      monoid
    else if laws == "commutative-monoid" then
      comm
    else if laws == "join-semilattice" then
      semilattice
    else if laws == "shadow" then
      (if absorbing then true else violate "right-absorption")
    else
      throw "den.disciplines: '${name}' declares unknown laws '${laws}' (harness)";

  # ── ONE LAWFUL SYNTHETIC PER LADDER CLASS (all four sampler branches execute) ────────────────────
  # ordered-monoid: list concatenation — associative with `[ ]` identity, NOT commutative (order-bearing,
  #   exactly the settings-layer / neron discipline shape the framework instances declare in later steps).
  # commutative-monoid: attrset-union over DISJOINT keys — associative + a `{ }` identity + commutative
  #   when the sample keys never collide, but NOT idempotent on multi-key values (distinguishes it from a
  #   semilattice: it is sampled commutatively over disjoint singletons).
  # join-semilattice: attrset-of-unit union (`//` over presence attrsets) — genuinely ACI (idempotent
  #   `a // a == a`, commutative + associative on unit values); the LAWFUL twin of the unlawful `a ++ b`.
  # shadow: attrset `//` last-wins over OVERLAPPING keys — Leijen's scoped-label record merge.
  lawfulInstances = {
    ord-append = {
      laws = "ordered-monoid";
      empty = [ ];
      combine = a: b: a ++ b;
    };
    comm-disjoint = {
      laws = "commutative-monoid";
      empty = { };
      combine = a: b: a // b;
    };
    join-unit = {
      laws = "join-semilattice";
      empty = { };
      combine = a: b: a // b;
    };
    shadow-lastwins = {
      laws = "shadow";
      empty = { };
      combine = a: b: a // b;
    };
  };

  # per-instance sample sets (declared beside the instance they exercise). Each set has ≥3 values incl.
  # the instance's `empty` and a DUPLICATED element (so idempotence has a witness of the collapse).
  lawfulSamples = {
    # lists incl. the empty list + a repeated element (`[ 1 ]` twice-over is `[ 1 1 ]`, not `[ 1 ]`).
    ord-append = [
      [ ]
      [ 1 ]
      [ 2 ]
      [ 1 ]
    ];
    # DISJOINT singleton attrsets (+ empty) sampled commutatively — no key collision, so union commutes.
    comm-disjoint = [
      { }
      { a = 1; }
      { b = 2; }
      { c = 3; }
    ];
    # presence attrsets (unit values) — `//` is idempotent on them (`{a={};} // {a={};} == {a={};}`).
    join-unit = [
      { }
      { a = { }; }
      { b = { }; }
      { a = { }; }
    ];
    # attrsets sharing their WHOLE key set (overlap) — `combine a b == b` (last-wins right-absorption).
    shadow-lastwins = [
      { k = 1; }
      { k = 2; }
      { k = 3; }
    ];
  };

  # THE HARNESS OVER THE COMPILED TABLE: register the lawful synthetics on `den.disciplines`, take the
  # COMPILED table back, and run `checkLaws` over EVERY registered entry using its declared sample set.
  # Iterating the compiled table (not `lawfulInstances` directly) is the AC: a framework instance
  # registered in a later step is covered automatically the moment it (and its samples) are added.
  compiledTable = (denHoag.mkDen [ { config.den.disciplines = lawfulInstances; } ]).den.disciplines;
  # every compiled discipline checked against its sample set — a discipline with no declared samples is
  # a harness gap, caught LOUD here (the sample map must cover the table).
  checkedTable = builtins.mapAttrs (
    name: entry:
    checkLaws {
      inherit name;
      inherit (entry) laws empty combine;
      samples =
        lawfulSamples.${name}
          or (throw "property-laws: registered discipline '${name}' has no sample set — add one beside its instance");
    }
  ) compiledTable;
  allLawful = builtins.all (v: v == true) (builtins.attrValues checkedTable);

  # ── TEETH PER LADDER CLASS: a deliberately UNLAWFUL synthetic per branch FAILS the check ─────────
  # each is a `checkLaws` call that MUST throw the named violation — `tryEval success` is false.
  teethFor =
    {
      name,
      laws,
      empty,
      combine,
      samples,
    }:
    (builtins.tryEval (
      builtins.deepSeq (checkLaws {
        inherit
          name
          laws
          empty
          combine
          samples
          ;
      }) null
    )).success;

  # ordered-monoid teeth: a non-associative combine (right-biased subtraction of list heads is not assoc).
  # `combine a b = if b == [] then a else b` — last-non-empty-wins is associative but NOT identity-lawful
  # on the LEFT (empty·x = x, but x·empty = x too… so pick a genuine non-associative op): drop-left, where
  # `a·b = tail(a) ++ b` — (a·b)·c != a·(b·c) because the tail is taken at different depths.
  teeth-ordered = teethFor {
    name = "bad-ordered";
    laws = "ordered-monoid";
    empty = [ ];
    combine = a: b: (if a == [ ] then [ ] else builtins.tail a) ++ b;
    samples = [
      [ ]
      [
        1
        2
      ]
      [ 3 ]
    ];
  };
  # commutative-monoid teeth: list-append is associative + `[ ]`-identity but NOT commutative
  # (`[1] ++ [2] != [2] ++ [1]`) — declared commutative-monoid, so the commutativity check fails.
  teeth-commutative = teethFor {
    name = "bad-commutative";
    laws = "commutative-monoid";
    empty = [ ];
    combine = a: b: a ++ b;
    samples = [
      [ ]
      [ 1 ]
      [ 2 ]
    ];
  };
  # join-semilattice teeth: THE canonical example — list-append is a monoid but NOT idempotent
  # (`[1] ++ [1] == [1 1] != [1]`), so a `laws = "join-semilattice"` declaration fails the idempotence
  # check. This is the `a ++ b` combine deliberately kept OUT of the lawful set-union carrier.
  teeth-semilattice = teethFor {
    name = "bad-semilattice";
    laws = "join-semilattice";
    empty = [ ];
    combine = a: b: a ++ b;
    samples = [
      [ ]
      [ 1 ]
      [ 1 ]
    ];
  };
  # shadow teeth: a LEFT-wins merge (`b // a`) does NOT right-absorb (`combine a b == a != b` on
  # overlapping keys) — declared shadow, so the right-absorption check fails.
  teeth-shadow = teethFor {
    name = "bad-shadow";
    laws = "shadow";
    empty = { };
    combine = a: b: b // a;
    samples = [
      { k = 1; }
      { k = 2; }
    ];
  };
in
{
  flake.tests.property-laws = {
    # ── the lawful table: every registered discipline satisfies its declared laws ──
    # the harness iterates the COMPILED den.disciplines table and passes every entry (all four ladder
    # branches exercised by the four lawful synthetics — future framework instances join automatically).
    test-lawful-table-all-pass = {
      expr = allLawful;
      expected = true;
    };
    # the table the harness checked is exactly the four registered synthetics (the iteration is real —
    # it reads the compiled table, not the raw fixture) — a self-documenting coverage pin.
    test-lawful-table-coverage = {
      expr = builtins.sort (a: b: a < b) (builtins.attrNames checkedTable);
      expected = [
        "comm-disjoint"
        "join-unit"
        "ord-append"
        "shadow-lastwins"
      ];
    };
    # each ladder branch's lawful synthetic passes standalone (the four branches all return true —
    # associativity+identity / +commutativity / +idempotence / right-absorption).
    test-lawful-ordered-monoid = {
      expr = checkLaws (
        lawfulInstances.ord-append
        // {
          name = "ord-append";
          samples = lawfulSamples.ord-append;
        }
      );
      expected = true;
    };
    test-lawful-commutative-monoid = {
      expr = checkLaws (
        lawfulInstances.comm-disjoint
        // {
          name = "comm-disjoint";
          samples = lawfulSamples.comm-disjoint;
        }
      );
      expected = true;
    };
    test-lawful-join-semilattice = {
      expr = checkLaws (
        lawfulInstances.join-unit
        // {
          name = "join-unit";
          samples = lawfulSamples.join-unit;
        }
      );
      expected = true;
    };
    test-lawful-shadow = {
      expr = checkLaws (
        lawfulInstances.shadow-lastwins
        // {
          name = "shadow-lastwins";
          samples = lawfulSamples.shadow-lastwins;
        }
      );
      expected = true;
    };

    # ── TEETH: a deliberately unlawful synthetic per ladder class FAILS the named-violation check ──
    # ordered-monoid: a non-associative combine trips the associativity law.
    test-teeth-ordered-non-associative = {
      expr = teeth-ordered;
      expected = false;
    };
    # commutative-monoid: list-append (order-bearing) trips the commutativity law.
    test-teeth-commutative-non-commutative = {
      expr = teeth-commutative;
      expected = false;
    };
    # join-semilattice: the canonical `a ++ b` (non-idempotent) trips the idempotence law.
    test-teeth-semilattice-non-idempotent = {
      expr = teeth-semilattice;
      expected = false;
    };
    # shadow: a left-wins merge trips the right-absorption (Leijen last-wins) law.
    test-teeth-shadow-non-absorbing = {
      expr = teeth-shadow;
      expected = false;
    };
  };
}
