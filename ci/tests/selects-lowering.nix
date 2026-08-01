# THE `selects` SURFACE: required, total, selector-valued — and the memo that decides when its matcher
# need not be called.
#
# The retiring surface was a three-valued field over `null | [ ] | [kindName…]` WITH A DEFAULT, so both
# of its absences could be produced by an omission. That is the defect this suite pins the removal of,
# and the removal has three halves, each with arms here:
#
#   (1) THE DOMAIN. One representation — a gen-select selector — and the two absences are two
#       CONSTRUCTORS applied to the same empty list (`sel.star` / `sel.any [ ]`), which are the opposite
#       empty-list identities of `builtins.all` and `builtins.any`. The empty list is not a selector, so
#       the constructor consuming it is the author's choice and neither absence can be landed on by
#       accident.
#   (2) REGISTRATION. Four arms, and the last three read ONE STRUCTURAL WALK over the selector tree.
#       A predicate on the outermost `__sel` is evaded by nesting — `sel.any [ … (sel.has …) ]` carries
#       tag `any` while its `has` child is matched normally — so every population below is exercised at
#       the ROOT and again NESTED, and the message carries the PATH to the offending node. The `@path`
#       cells are what makes that a measurement rather than a claim.
#   (3) THE MEMO. `kindDetermined` names the fragment whose answer is provably a function of node kind
#       alone; the index memoises only that fragment and answers everything else per node. Its
#       `positionDependent` is the scaling observable.
#
# ★ WHY THE MESSAGE TEXT IS READ RATHER THAN A THROW CAUGHT. `policyMessage` returns its verdict as a
# VALUE (`null` = clean) precisely because Nix cannot recover a caught throw's text, so a validator that
# returns is the only CI-testable form. These arms classify that value by matching on the clause each
# message owns, so a rewording that keeps the clause keeps the arm and a rewording that drops it reddens.
{
  denHoag,
  denCompat,
  ...
}:
let
  inherit (denHoag) sel;
  msg = denHoag.internal.policyMessage;
  ixOf = denHoag.internal.indexPolicySelection;

  body = _ctx: [ ];
  verdict =
    s:
    msg {
      p = {
        emits = [ ];
        selects = s;
        fn = body;
      };
    };
  # The ARM a message names, read off the clause that arm owns.
  armOf =
    m:
    if m == null then
      "admitted"
    else if builtins.match ".*declares no .selects.*" m != null then
      "missing"
    else if builtins.match ".*unknown tag.*" m != null then
      "unknown"
    else if builtins.match ".*which the dispatch context cannot interpret.*" m != null then
      "refused"
    else if builtins.match ".*whose payload field.*" m != null then
      "malformed"
    else if builtins.match ".*not STRATUM-STABLE.*" m != null then
      "unstable"
    else
      "UNCLASSIFIED: ${m}";
  # The GROUND an unstable verdict reports. Two grounds, because they tell an author two different
  # things: a positional selector is refused at a stratum that has no positions yet, and an
  # `__entry`-reading one because a completion may null the entry. An author who cannot tell them apart
  # cannot tell which repair to make, so the discrimination is asserted and not assumed.
  groundOf =
    m:
    if m == null then
      "-"
    else if builtins.match ".*may null that entry.*" m != null then
      "entry"
    else if builtins.match ".*where the node sits in the scope graph.*" m != null then
      "position"
    else
      "-";
  # The PATH the message reports, read off its own text — `<root>` where it names no sub-selector.
  pathOf =
    m:
    let
      g = if m == null then null else builtins.match ".*the selector at .([^`]*).*" m;
    in
    if m == null then
      "-"
    else if g == null then
      "<root>"
    else
      builtins.head g;
  # one cell: the arm and the path, as one comparable string.
  cell =
    s:
    let
      m = verdict s;
    in
    "${armOf m} @${pathOf m}";
  # the nesting harness: the value under test as the SECOND element of a disjunction, so its own tag is
  # never the outermost one. Index 1 is what the reported path must name.
  nest =
    s:
    sel.any [
      (sel.attrs { type = "host"; })
      s
    ];

  # ARM 5's harness varies the CODOMAIN as well as the selector, because arm 5 is the only registration
  # refusal that is a property of the PAIR: the identical selector is admitted on a record emitting
  # `edge` and refused on one emitting `suppress`. The codomain-dependent required fields ride along —
  # `suppresses` for the exclude family, `binds` for the resolve family — because without them the
  # codomain guard answers first and every cell would be measuring a different refusal.
  verdictOf =
    emits: s:
    msg {
      p = {
        inherit emits;
        selects = s;
        fn = body;
      }
      // (if builtins.elem "suppress" emits then { suppresses = [ ]; } else { })
      // (if builtins.elem "member" emits then { binds = [ ]; } else { });
    };
  # one cell: the arm, the ground and the path, as one comparable string.
  pairCell =
    emits: s:
    let
      m = verdictOf emits s;
    in
    "${armOf m}:${groundOf m} @${pathOf m}";

  # `kindDetermined`, read through the index's own observable rather than through a private predicate:
  # a one-rule feed is kind-determined iff nothing lands in `positionDependent`.
  isKindDetermined =
    s:
    (ixOf
      [ "host" ]
      [
        {
          identity = "r";
          selects = s;
        }
      ]
    ).positionDependent == [ ];
in
{
  flake.tests.selects-lowering = {
    # ── (1) THE DOMAIN: three canonical values, three different selections, one field ────────────────
    # The two absences are DIFFERENT CONSTRUCTORS over the same empty list, and the index puts them at
    # opposite extremes of one table. Asserted together, because their being opposite is the property —
    # either alone is satisfied by a value that does nothing.
    test-the-two-absences-are-opposite = {
      expr =
        let
          feedOf = s: [
            {
              identity = "r";
              selects = s;
            }
          ];
          selectedBy =
            s:
            map (r: r.identity) ((ixOf [ "host" ] (feedOf s)).at (_: _: throw "unreachable") "host:h1" "host");
        in
        {
          everywhere = selectedBy sel.star;
          nowhere = selectedBy (sel.any [ ]);
          # `sel.and [ ]` is denotationally `sel.star` and stays legal because gen-select defines it; it
          # is not offered as a canonical value, which is why it is pinned as a classification and not
          # advertised as a spelling.
          emptyConjunction = selectedBy (sel.and [ ]);
          constrainedHit = selectedBy (sel.attrs { type = "host"; });
          constrainedMiss = map (r: r.identity) (
            (ixOf [ "host" "user" ] (feedOf (sel.attrs { type = "user"; }))).at (
              _: _: throw "unreachable"
            ) "host:h1" "host"
          );
        };
      expected = {
        everywhere = [ "r" ];
        nowhere = [ ];
        emptyConjunction = [ "r" ];
        constrainedHit = [ "r" ];
        constrainedMiss = [ ];
      };
    };

    # ── (2) REGISTRATION ─────────────────────────────────────────────────────────────────────────────
    # ARM 1 — the omission itself. This is the whole point of the field being required: silence is not a
    # spelling of any of the three selections.
    test-omitted-selects-is-refused = {
      expr = armOf (msg {
        p = {
          emits = [ ];
          fn = body;
        };
      });
      expected = "missing";
    };

    # ARM 2 — an unrecognised tag, a NON-STRING tag, and a value that is not a selector at all. The
    # renderer is `builtins.typeOf`-based and therefore total: a function tag and a SELF-REFERENTIAL
    # attrset tag are both rendered rather than aborting the checker, which is what a `toJSON`-based
    # renderer does on exactly these two. `sel.not "nope"` is the descent case — the recursion meets the
    # root guard, which is why `selector` needs no type test of its own.
    test-arm2-unknown-at-every-depth = {
      expr = {
        notASelector = cell null;
        notASelectorInt = cell 7;
        topBogus = cell { __sel = "bogus"; };
        nestedBogus = cell (nest {
          __sel = "bogus";
        });
        nestedBoolean = cell (nest {
          __sel = false;
        });
        functionTag = cell { __sel = x: x; };
        recursiveSetTag = cell (
          let
            r = {
              __sel = r;
            };
          in
          r
        );
        notPayloadString = cell (sel.not "nope");
        withinPayloadInt = cell (sel.within 3);
        parentMatchesPayloadList = cell (sel.parentMatches [ ]);
      };
      expected = {
        notASelector = "unknown @<root>";
        notASelectorInt = "unknown @<root>";
        topBogus = "unknown @<root>";
        nestedBogus = "unknown @/1";
        nestedBoolean = "unknown @/1";
        functionTag = "unknown @<root>";
        recursiveSetTag = "unknown @<root>";
        notPayloadString = "unknown @/not";
        withinPayloadInt = "unknown @/within";
        parentMatchesPayloadList = "unknown @/parentMatches";
      };
    };

    # ARM 3 — the three tags the dispatch context cannot interpret, at any depth. `coord` needs a
    # `__coords` projection the scope context does not carry; `has` and `when` can read `ctx.children`,
    # an attribute the dispatch sites are upstream of. The `when` refusal is not free and the price is
    # asserted rather than left implicit: den-hoag's OWN `hasClass` sugar is a `when`, so it is
    # inadmissible in `selects` — the message says so by name, which is the difference between an author
    # finding their record and hunting for a `when` they never typed.
    test-arm3-refused-at-every-depth = {
      expr = {
        topHas = cell (sel.has sel.star);
        nestedHas = cell (nest (sel.has sel.star));
        nestedWhen = cell (nest (sel.when (_: _: true)));
        coordDeeplyNested = cell (
          sel.not (
            nest (
              sel.within {
                __sel = "coord";
                dim = "d";
                id_hash = "x";
              }
            )
          )
        );
        ownHasClassSugar = cell (denHoag.hasClass "nixos");
        # …and the message names the sugars, so the author is not sent looking for a tag they never wrote.
        namesTheSugars = builtins.match ".*hasClass.*" (verdict (denHoag.hasClass "nixos")) != null;
      };
      expected = {
        topHas = "refused @<root>";
        nestedHas = "refused @/1";
        nestedWhen = "refused @/1";
        coordDeeplyNested = "refused @/not/1/within";
        ownHasClassSugar = "refused @<root>";
        namesTheSugars = true;
      };
    };

    # ARM 4 — a RECOGNISED, admissible tag whose own payload is unusable. Two faults, one arm: ABSENT,
    # and PRESENT AT THE WRONG TYPE. Registration is the only total position at which the field can be
    # established usable — an arm guarding only the tag lets `s.selectors` abort inside the walk's own
    # descent, and an arm guarding only PRESENCE lets `builtins.attrNames` abort one stage later, in the
    # kind-determined classifier. Both faults are exercised, and the message distinguishes them.
    test-arm4-malformed-payload-absent-and-mistyped = {
      expr = {
        anyNoSelectors = cell { __sel = "any"; };
        notNoSelector = cell { __sel = "not"; };
        attrsNoA = cell { __sel = "attrs"; };
        nestedAnyNoSelectors = cell (nest {
          __sel = "any";
        });
        anySelectorsString = cell {
          __sel = "any";
          selectors = "nope";
        };
        anySelectorsInt = cell {
          __sel = "any";
          selectors = 1;
        };
        andSelectorsSet = cell {
          __sel = "and";
          selectors = { };
        };
        attrsAString = cell {
          __sel = "attrs";
          a = "nope";
        };
        nestedAnySelectorsString = cell (nest {
          __sel = "any";
          selectors = "nope";
        });
      };
      expected = {
        anyNoSelectors = "malformed @<root>";
        notNoSelector = "malformed @<root>";
        attrsNoA = "malformed @<root>";
        nestedAnyNoSelectors = "malformed @/1";
        anySelectorsString = "malformed @<root>";
        anySelectorsInt = "malformed @<root>";
        andSelectorsSet = "malformed @<root>";
        attrsAString = "malformed @<root>";
        nestedAnySelectorsString = "malformed @/1";
      };
    };

    # …and the message DISCRIMINATES the two faults, which is why the arm carries a `found` field at all:
    # `<absent>` says add the field, a rendered type says the field is there and holds the wrong thing.
    # Without this, an author whose `selectors` is present reads their record, sees the field, and
    # concludes the checker is wrong.
    test-arm4-names-the-field-and-what-was-found = {
      expr = {
        absent =
          builtins.match ".*`selectors` is `<absent>`.*" (verdict {
            __sel = "any";
          }) != null;
        mistyped =
          builtins.match ".*`selectors` is `<string>`.*" (verdict {
            __sel = "any";
            selectors = "nope";
          }) != null;
      };
      expected = {
        absent = true;
        mistyped = true;
      };
    };

    # THE PAYLOADS THAT NEED NO TYPE TEST, exhibited rather than argued. `kind` and `id_hash` have one
    # consumer each and it is `==`, which is total across Nix types — so a function there is ADMITTED and
    # simply never matches. This is the positive half of the field sweep: the arms above show what a
    # missing type test costs, and this shows the two rows where adding one would be ceremony.
    test-total-by-operation-payloads-are-admitted = {
      expr = {
        kindFn = cell {
          __sel = "kind";
          kind = x: x;
        };
        entityFn = cell {
          __sel = "entity";
          id_hash = x: x;
        };
      };
      expected = {
        kindFn = "admitted @-";
        entityFn = "admitted @-";
      };
    };

    # THE CONTROLS FOR ALL FOUR ARMS, in the same run. Without these the arms above are satisfied by a
    # walk that refuses everything, and a suite of refusals proves nothing about a checker.
    test-walk-admits-every-wellformed-value = {
      expr = {
        star = cell sel.star;
        emptyAny = cell (sel.any [ ]);
        attrs = cell (sel.attrs { type = "host"; });
        kind = cell (
          sel.kind {
            kind = "host";
            options = { };
          }
        );
        disjunction = cell (
          sel.any [
            (sel.attrs { type = "host"; })
            (sel.attrs { type = "user"; })
          ]
        );
        # the position-dependent shape: ADMITTED (it is not refused — it is priced per node), which is
        # what keeps arm 3 a statement about the three refused tags and not about positionality.
        hostsAndTheirDescendants = cell (
          sel.any [
            (sel.attrs { type = "host"; })
            (sel.within (sel.attrs { type = "host"; }))
          ]
        );
        nestedNot = cell (sel.not (sel.not sel.star));
      };
      expected = {
        star = "admitted @-";
        emptyAny = "admitted @-";
        attrs = "admitted @-";
        kind = "admitted @-";
        disjunction = "admitted @-";
        hostsAndTheirDescendants = "admitted @-";
        nestedNot = "admitted @-";
      };
    };

    # ARM 5 — the STRATUM-STABILITY refusal, and it is a property of the PAIR (`emits`, `selects`) rather
    # than of the selector alone. A record whose codomain reaches a family the staged pre-pass dispatches
    # must carry a selector whose answer is the same in EVERY completion of the pre-pass's graph: that
    # pass fires over the attachment-free node set, and the containment edges a positional selector would
    # read are the pass's own output, so there is no later at which to retry the query. `sel.kind` and
    # `sel.entity` fail for the second reason — they read the `__entry`-derived identity, and a
    # completion may null a node's entry.
    #
    # NESTING CANNOT EVADE IT, for the same reason arms 2-4 walk: the check is `kindDetermined`'s
    # recursion with one leaf flipped, so a `within` buried under an `any` is refused AT the `within`,
    # WITH its path. A top-tag test would admit every cell below whose name starts `nested`.
    test-arm5-prepass-stratum-refusal-at-every-depth = {
      expr = {
        topWithinOnSuppress = pairCell [ "suppress" ] (sel.within (sel.attrs { type = "env"; }));
        nestedWithinOnSuppress = pairCell [ "suppress" ] (nest (sel.within (sel.attrs { type = "env"; })));
        nestedWithinOnMember = pairCell [ "member" ] (nest (sel.within (sel.attrs { type = "env"; })));
        deeplyNestedParentMatches = pairCell [ "suppress" ] (
          sel.not (nest (sel.parentMatches (sel.attrs { type = "env"; })))
        );
        # the payload-shape row: an `attrs` reading anything but `type` reads a decl key, and the decls
        # are exactly what a completion injects.
        attrsTwoKeysOnSuppress = pairCell [ "suppress" ] (
          sel.attrs {
            type = "host";
            other = 1;
          }
        );
        # the ENTRY ground, at both depths and on both feeds.
        kindOnSuppress = pairCell [ "suppress" ] (
          sel.kind {
            kind = "host";
            options = { };
          }
        );
        nestedKindOnMember = pairCell [ "member" ] (
          nest (
            sel.kind {
              kind = "host";
              options = { };
            }
          )
        );
        entityOnSuppress = pairCell [ "suppress" ] (sel.entity { id_hash = "x"; });
      };
      expected = {
        topWithinOnSuppress = "unstable:position @<root>";
        nestedWithinOnSuppress = "unstable:position @/1";
        nestedWithinOnMember = "unstable:position @/1";
        deeplyNestedParentMatches = "unstable:position @/not/1";
        attrsTwoKeysOnSuppress = "unstable:position @<root>";
        kindOnSuppress = "unstable:entry @<root>";
        nestedKindOnMember = "unstable:entry @/1";
        entityOnSuppress = "unstable:entry @<root>";
      };
    };

    # THE CONTROLS FOR ARM 5, in the same run, and there are two independent ones because the refusal has
    # two conjuncts. Without the first, the arm above is satisfied by a check that refuses every
    # pre-pass record; without the second, by one that refuses those selectors everywhere.
    test-arm5-controls-both-conjuncts = {
      expr = {
        # (a) THE FRAGMENT is live: stratum-stable selectors register clean ON the pre-pass feeds.
        starOnSuppress = pairCell [ "suppress" ] sel.star;
        emptyAnyOnSuppress = pairCell [ "suppress" ] (sel.any [ ]);
        attrsTypeOnMember = pairCell [ "member" ] (sel.attrs { type = "host"; });
        booleanCombinationOnSuppress = pairCell [ "suppress" ] (
          sel.not (
            sel.any [
              (sel.attrs { type = "host"; })
              (sel.attrs { type = "user"; })
            ]
          )
        );
        # (b) THE CODOMAIN is what makes the pair: the SAME values, refused above, register clean on a
        #     record whose `emits` no pre-pass feed dispatches.
        withinOnEdge = pairCell [ "edge" ] (sel.within (sel.attrs { type = "env"; }));
        kindOnEdge = pairCell [ "edge" ] (
          sel.kind {
            kind = "host";
            options = { };
          }
        );
        withinOnEmptyCodomain = pairCell [ ] (sel.within (sel.attrs { type = "env"; }));
      };
      expected = {
        starOnSuppress = "admitted:- @-";
        emptyAnyOnSuppress = "admitted:- @-";
        attrsTypeOnMember = "admitted:- @-";
        booleanCombinationOnSuppress = "admitted:- @-";
        withinOnEdge = "admitted:- @-";
        kindOnEdge = "admitted:- @-";
        withinOnEmptyCodomain = "admitted:- @-";
      };
    };

    # ARM 5 IS NOT A FIFTH ARM OF THE SELECTOR WALK, and the ordering is what says so. A `has` on an
    # exclude-family record is still arm 3's refusal: arms 2-4 read one walk over one selector and their
    # answer is a property of the selector alone, so they are decided before a question that needs the
    # record. Folding arm 5 into that walk would make its answer depend on a record it does not receive.
    test-arm5-does-not-displace-the-selector-walk = {
      expr = {
        hasOnSuppress = pairCell [ "suppress" ] (sel.has sel.star);
        bogusTagOnSuppress = pairCell [ "suppress" ] (nest {
          __sel = "bogus";
        });
        malformedOnMember = pairCell [ "member" ] (nest {
          __sel = "any";
        });
      };
      expected = {
        hasOnSuppress = "refused:- @<root>";
        bogusTagOnSuppress = "unknown:- @/1";
        malformedOnMember = "malformed:- @/1";
      };
    };

    # THE MESSAGE CARRIES WHAT THE AUTHOR NEEDS TO ACT: the rule's own identity, the vocabulary that put
    # it in scope of the check, and a repair. The vocabulary is rendered FROM the declaration vocabulary
    # rather than spelled in the message, so a kind entering the pre-pass appears here without an edit.
    test-arm5-message-names-rule-vocabulary-and-repair = {
      expr =
        let
          m = verdictOf [ "suppress" ] (sel.within (sel.attrs { type = "env"; }));
        in
        {
          namesTheRule = builtins.match ".*`p`.selects.*" m != null;
          namesTheFeedVocabulary = builtins.match ".*member, suppress.*" m != null;
          namesTheRepair = builtins.match ".*Write a selector over .type. alone.*" m != null;
        };
      expected = {
        namesTheRule = true;
        namesTheFeedVocabulary = true;
        namesTheRepair = true;
      };
    };

    # ── (3) THE MEMO ─────────────────────────────────────────────────────────────────────────────────
    # THE FRAGMENT, row by row. `attrs` is kind-determined IFF its payload is exactly `{ type = …; }` —
    # the scope adapter merges `type` last so it is present on every node and unshadowable, but a second
    # key is a read of something else. `when` never reaches here (arm 3 refuses it), and the direction of
    # approximation on everything else is the FINER one: over-classifying as position-dependent costs
    # evaluations, over-classifying as kind-determined mis-selects.
    test-kind-determined-fragment = {
      expr = builtins.mapAttrs (_: isKindDetermined) {
        star = sel.star;
        emptyAny = sel.any [ ];
        attrsType = sel.attrs { type = "host"; };
        attrsTwoKeys = sel.attrs {
          type = "host";
          other = 1;
        };
        kind = sel.kind {
          kind = "host";
          options = { };
        };
        disjunction = sel.any [
          (sel.attrs { type = "host"; })
          (sel.attrs { type = "user"; })
        ];
        notStar = sel.not sel.star;
        within = sel.within (sel.attrs { type = "host"; });
        parentMatches = sel.parentMatches (sel.attrs { type = "host"; });
        entity = sel.entity {
          id_hash = "x";
          name = "x";
        };
        hostsAndTheirDescendants = sel.any [
          (sel.attrs { type = "host"; })
          (sel.within (sel.attrs { type = "host"; }))
        ];
      };
      expected = {
        star = true;
        emptyAny = true;
        attrsType = true;
        attrsTwoKeys = false;
        kind = true;
        disjunction = true;
        notStar = true;
        within = false;
        parentMatches = false;
        entity = false;
        hostsAndTheirDescendants = false;
      };
    };

    # ORDER IS PRESERVED BY CONSTRUCTION, which is why the memo is a parallel boolean vector at the
    # feed's own positions rather than a sub-list. Dispatch order determines emission order and therefore
    # merge order, so an index that partitioned the feed and concatenated the halves would produce a
    # mis-ordered intermediate — and a later sort repairing it is how an order defect closes falsely.
    # The mixed feed below interleaves the two classes, so a partition WOULD reorder it.
    test-selection-preserves-feed-order = {
      expr =
        let
          feed = [
            {
              identity = "a";
              selects = sel.attrs { type = "host"; };
            }
            {
              identity = "b";
              selects = sel.within (sel.attrs { type = "host"; });
            }
            {
              identity = "c";
              selects = sel.star;
            }
          ];
        in
        map (r: r.identity) ((ixOf [ "host" ] feed).at (_: _: true) "host:h1" "host");
      expected = [
        "a"
        "b"
        "c"
      ];
    };

    # THE SHORT-CIRCUIT AND THE GENERAL ARM ARE DIFFERENT PROGRAMS, and which one runs is decided by
    # `positionDependent` alone. Under a kind-determined feed the matcher is NEVER applied — asserted by
    # handing it a throw — and the moment a positional rule enters the feed it is the first thing that
    # runs. Those two facts are the whole composition argument, so they are one arm.
    test-matcher-is-applied-exactly-when-it-is-needed = {
      expr =
        let
          poison = r: _id: throw "matchAt applied for ${r.identity}";
          clean = [
            {
              identity = "a";
              selects = sel.attrs { type = "host"; };
            }
          ];
          positional = [
            {
              identity = "b";
              selects = sel.within (sel.attrs { type = "host"; });
            }
          ];
          cleanIx = ixOf [ "host" ] clean;
          posIx = ixOf [ "host" ] positional;
        in
        {
          cleanObservable = builtins.length cleanIx.positionDependent;
          positionalObservable = builtins.length posIx.positionDependent;
          shortCircuitNeverApplies = map (r: r.identity) (cleanIx.at poison "host:h1" "host");
          generalArmApplies =
            !(builtins.tryEval (builtins.deepSeq (posIx.at poison "host:h1" "host") null)).success;
        };
      expected = {
        cleanObservable = 0;
        positionalObservable = 1;
        shortCircuitNeverApplies = [ "a" ];
        generalArmApplies = true;
      };
    };

    # TOTALITY OVER NODE KINDS, unchanged and re-pinned on the new index. A kind outside the memo's hint
    # list RECOMPUTES rather than reading a table with an `or [ ]` fallback — that fallback would answer
    # "no rules here" for an unknown kind, silently dropping every unconstrained rule at that node, which
    # is the failure mode this whole design removes, reintroduced at the read.
    test-index-is-total-over-kinds-outside-the-hint = {
      expr =
        let
          feed = [
            {
              identity = "everywhere";
              selects = sel.star;
            }
            {
              identity = "hostsOnly";
              selects = sel.attrs { type = "host"; };
            }
          ];
          at = kind: map (r: r.identity) ((ixOf [ "host" ] feed).at (_: _: throw "unreachable") "n:1" kind);
        in
        {
          inHint = at "host";
          outsideHint = at "cluster";
        };
      expected = {
        inHint = [
          "everywhere"
          "hostsOnly"
        ];
        outsideHint = [ "everywhere" ];
      };
    };

    # ── (4) THE COMPAT PRODUCERS, at the two arms that used to disagree ──────────────────────────────
    # The defect in one assertion: the SAME empty input, the two producers, opposite answers — which is
    # correct and always was, and which used to be spelled `[ ] ↦ null` beside `[ ] ↦ [ ]` in one compile
    # unit. Read off a compiled fleet rather than off the helpers, so it is the shipped lowering that is
    # pinned and not a restatement of it.
    #
    # `orphan` is registered and included nowhere, so the schema arm answers NOWHERE. `ungated` rides
    # `den.default.includes` with no entity-kind formal, so the formals arm answers EVERYWHERE.
    test-the-two-producers-answer-opposite-on-the-empty-input = {
      expr =
        let
          compiled = denCompat.compileFull {
            aspects.a = { };
            policies.orphan = {
              __isPolicy = true;
              name = "orphan";
              emits = [ "enrich" ];
              fn = _ctx: [
                (denHoag.declare.enrich {
                  key = "k";
                  value = 1;
                })
              ];
            };
            default.includes = [
              {
                __isPolicy = true;
                name = "ungated";
                emits = [ "edge" ];
                fn = _ctx: [ (denHoag.declare.edge { name = "a"; }) ];
              }
            ];
            schema.host.parent = null;
          };
        in
        {
          schemaArmOnEmpty = compiled.policies.orphan.selects;
          formalsArmOnEmpty = compiled.policies.__aspectInclude__ungated.selects;
        };
      expected = {
        schemaArmOnEmpty = sel.any [ ];
        formalsArmOnEmpty = sel.star;
      };
    };

    # …and the NON-empty inputs, including the one class that exercises the normalising helper's
    # non-singleton branch. A singleton is the BARE literal and never a one-element `any`: two spellings
    # of one selection is this design's own defect, one level down.
    #
    # ★ THE REFERENCE FORM IS LOAD-BEARING, and it is the reason this arm looks indirect. A policy
    # RECORD in an includes list is removed from the fleet-wide compiled set and fires through its own
    # `__kindInclude__` arm instead, so its selection comes from that arm and never from the schema. The
    # schema arm is reached by a NAME-ONLY reference, which `includedAt` sees and the removal set does
    # not — so this is the shape that actually exercises `selectsFromSchema`, and asserting it through a
    # record reference would have pinned a different producer while reading as if it pinned this one.
    test-schema-arm-kind-disjunction-is-normalised = {
      expr =
        let
          p = name: {
            __isPolicy = true;
            inherit name;
            emits = [ "enrich" ];
            fn = _ctx: [
              (denHoag.declare.enrich {
                key = "k";
                value = 1;
              })
            ];
          };
          compiled = denCompat.compileFull {
            policies = {
              oneKind = p "oneKind";
              twoKinds = p "twoKinds";
            };
            schema = {
              host = {
                parent = null;
                includes = [
                  { name = "oneKind"; }
                  { name = "twoKinds"; }
                ];
              };
              user = {
                parent = "host";
                includes = [ { name = "twoKinds"; } ];
              };
            };
          };
        in
        {
          singleton = compiled.policies.oneKind.selects;
          disjunction = compiled.policies.twoKinds.selects;
        };
      expected = {
        singleton = sel.attrs { type = "host"; };
        disjunction = sel.any [
          (sel.attrs { type = "host"; })
          (sel.attrs { type = "user"; })
        ];
      };
    };
  };
}
