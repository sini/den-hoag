# A11 — THE RECORDS BINDING SURFACE AND ITS SHADOW REFUSALS (`output-modules.nix`).
#
# `channelSurfacesAt` yields TWO surfaces from one `id`-application: the FLAT `values` (deferral
# normalised, list emissions spread — the shipped binding) and `records` (one record per contribution,
# provenance kept). `bindingsAt` appends `records` as the binding SIBLING `channels`, beside the shipped
# `settings`.
#
# `//` is RIGHT-BIASED, so an appended sibling silently REPLACES any earlier operand's key of the same
# name. That is the silent-vanish class one level up from the surface it guards, so the sibling set is
# refused at two grains: per FLEET on the registration (forced on the `systems` path, so it fires even for
# a fleet that wraps no class modules) and per NODE on the whole binding key space (forced with the binding
# set). Both are FILTERS, not `builtins.any` — their messages interpolate the key, and a Bool cannot name
# the thing the message names.
#
# Two arms on the records surface, five on the refusal — ONE PER ORIGIN of the fold, not one per operand:
# two of the three operands are themselves `//`-merges with different writers, so an arm per operand would
# leave a writer with no fixture and a remedy that reaches nobody.
#
# Beside those, two families that assert the RENDER rather than the refusal:
#
#   • THE FOUR JOINS. Both messages are folds, and four separators are the expressions that perform them:
#     `" and "` between origin LABELS, `"; "` between origin REMEDIES, `", "` between SIBLING names, `" "`
#     between per-witness CLAUSES. A join is asserted only by a substring that SPANS it, and every
#     origin/remedy arm above pins text sitting strictly INSIDE one clause of one origin — so each
#     separator could be changed to any other string and not one of them would move. The join arms are the
#     only ones here whose pinned text crosses a separator.
#   • THE GRAIN PAIR. `channels` reaching `base` by a gathered key alone is the PER-NODE refusal; the same
#     key additionally REGISTERED is the FLEET one, forced earlier on the `systems` path. "Escalates" is a
#     claim about a TRANSITION, so it needs both endpoints and the endpoints are two different fleets: a
#     boolean over one of them states neither. The negative half — that check 2's text does NOT render once
#     the fleet check fires — is what makes preemption executable rather than argued.
#
# COVERAGE LIMIT, stated: the fifth origin (`localKeys` — a channel a quirk's own `ops` or a
# collection-stratum `route`/`join`/`tee` DERIVES under a sibling name, present in `received id` and absent
# from `attrNames den.quirks`) has NO fixture here. Reaching it needs the derived-channel composition path,
# which is red at this commit; a fixture that merely REGISTERS the name exercises the `channelKeys` origin
# instead and could never show the derived case getting its own remedy. Its discriminator is exercised only
# by the totality argument in the source, not by a witness.
{ denHoag, ... }:
let
  d = denHoag.declare;
  system = "x86_64-linux";

  # ── the fixture fleet: one `unit` root producing nixos content, one registered channel `ch` it emits ──
  # `system` is a DECLARED kind option so it rides on `__entry.system` — the coordinate the scopeRoots fold
  # selects a `den.systemViews` entry by, which is what the decls-writer arm needs.
  fleet =
    {
      quirks ? {
        ch = { };
      },
      gather ? null,
      policies ? { },
      systemViews ? { },
    }:
    [
      {
        config.den.schema.unit = {
          parent = null;
          options.system = denHoag.schema.mkOption {
            type = denHoag.schema.types.str;
            default = system;
          };
        };
      }
      { config.den.unit.u1.system = system; }
      { config.den.contentClass.unit = "nixos"; }
      { config.den.quirks = quirks; }
      (
        { config, ... }:
        {
          config.den.aspects.emit = {
            ch = [ { dir = "d1"; } ];
            nixos =
              { ch, ... }:
              {
                networking.hostName = "u1";
                nixpkgs.hostPlatform = system;
              };
          };
          config.den.include = [
            {
              at = config.den.unit.u1;
              aspects = [ config.den.aspects.emit ];
            }
          ];
        }
      )
      { config.den.policies = policies; }
      { config.den.systemViews = systemViews; }
    ]
    ++ (if gather == null then [ ] else [ { config.den.channelGather = gather; } ]);

  # The nixpkgs-free `collect` terminal EXPOSES `bindings`, so both surfaces are read directly, forcing no
  # module fn. Reaching `.systems` at all forces the FLEET refusal (the `builtins.seq` on `systems`).
  bindingsOf = args: (denHoag.mkDen (fleet args)).den.output.systems.nixos."unit:u1".bindings;

  plain = bindingsOf { };

  # ── the deferred arm's supplier ──────────────────────────────────────────────────────────────────────
  # A DEFERRED contribution whose raw `value` is gen-pipe's POISON shape — a throw. The records surface
  # must route through `extractContribution`, which takes the `fn` branch and never touches `value`; a
  # surface handing the raw `c` through would hand the consumer that throw, and `c.value or [ ]` would NOT
  # rescue it (`or` defaults an ABSENT attribute, it does not catch a raised one).
  deferredGather =
    _derivedBaseNames: _result: id:
    if id == "unit:u1" then
      {
        ch = [
          {
            deferred = true;
            # the contribution's producing CLASS ENTRY (`producerKeyOf` reads `.name`) and producing
            # entity — together they are the producer-config map key the thunk is stamped with.
            class.name = "nixos";
            producer.entity.id_hash = "u1hash";
            fn = _cfg: { resolved = "at-producing-scope"; };
            value = throw "A11: the RAW poison value of a deferred contribution was forced";
          }
        ];
      }
    else
      { };

  # ── the gathered-surface arm's supplier ──────────────────────────────────────────────────────────────
  # A key equal to a sibling name reaching `base` through `surfaces.values` ALONE: registered as no
  # channel, enriched by no policy, derived by no op.
  shadowGather =
    _derivedBaseNames: _result: id:
    if id == "unit:u1" then
      {
        channels = [
          {
            deferred = false;
            value = "gathered-shadow";
          }
        ];
      }
    else
      { };

  # ── the JOIN-RENDER fleets ───────────────────────────────────────────────────────────────────────────
  # A key of origin ARITY TWO: `channels` reaches `base` through `inherited` (the `den.systemViews.<system>`
  # entry) AND through `owners` (the enriching policy). `originsOf` therefore returns two records, and
  # check 2 renders the labels join and the remedies join — neither of which any single-origin fleet can
  # produce. Every check-2 message ends with the sibling sentence, so this one fleet also reaches the
  # sibling join: three of the four.
  #
  # It is a NEW fleet rather than a second origin added to the decls-writer arms', and that is a
  # correctness point, not a filing one. Those arms pin SINGLE-ORIGIN-SHAPED text — `is a scope-inherited
  # declaration key`, whose leading `is ` renders only while that origin is the key's SOLE origin. Give
  # them a second origin and the same clause renders `… and a scope-inherited declaration key …`, so the
  # assertion dies. Widening an existing fleet to cover a join would have broken the arm it was widening.
  multiOrigin = bindingsOf {
    systemViews.${system}.channels = "from-the-system-view";
    policies.writeChannelsKey = {
      emits = [ "enrich" ];
      fn = _ctx: [
        (d.enrich {
          key = "channels";
          value = "enriched";
        })
      ];
    };
  };

  # BOTH sibling names registered, so `collidingRegistered` carries two witnesses and check 1 folds TWO
  # clauses into one abort. This is the only join `multiOrigin` cannot reach — a one-witness message has no
  # clause boundary — and it is the join whose loss costs the most: a dropped clause is a MISSING OWNER,
  # not a misformatted string. `throw` takes one string, so the fold is the only way the second owner is
  # told at all.
  twoRegisteredSiblings = bindingsOf {
    quirks = {
      ch = { };
      channels = { };
      settings = { };
    };
  };

  # ── the ESCALATION exhibit's fleet: the gathered key, ALSO REGISTERED ─────────────────────────────────
  # The "after" endpoint of the transition arm (6a) asserts; the gather-only fleet above is the
  # "before". The two differ in exactly one thing — the `channels` registration — which is what makes the
  # pair a measurement of the escalation rather than two unrelated aborts.
  registeredAndGathered = bindingsOf {
    quirks = {
      ch = { };
      channels = { };
    };
    gather = shadowGather;
  };
in
{
  flake.tests.channel-binding-siblings = {
    # ── (1) ADDITIVE: the flat surface is unchanged, and the records sibling carries PROVENANCE ─────────
    # The flat `ch` binding is exactly the value the pre-split single-surface expression produced (v1
    # flattenAndExtract — the list emission SPREAD into elements), and the new `channels` sibling carries
    # one RECORD per contribution with its producer intact. A fixture asserting only that `channels` exists
    # would pass against a surface that dropped the provenance this whole arm is for.
    test-additive-flat-surface-unchanged = {
      expr = plain.ch;
      expected = [ { dir = "d1"; } ];
    };
    # THE ARITY DIVERGENCE, pinned rather than left implicit: the records surface keeps the flat path's
    # deferral step and deliberately DROPS its list SPREAD, because spreading is what destroys the
    # one-record-one-contribution correspondence the surface exists for. So ONE list emission is ONE record
    # whose `value` is the whole list, where the flat surface shows two-element-free spread elements.
    test-additive-records-sibling-carries-producer = {
      expr =
        let
          recs = plain.channels.ch;
          r = builtins.head recs;
        in
        {
          count = builtins.length recs;
          value = r.value;
          hasProducer = r ? producer && r.producer ? entity;
        };
      expected = {
        count = 1;
        value = [ { dir = "d1"; } ];
        hasProducer = true;
      };
    };

    # ── (2) DEFERRED: the records surface keeps the deferred-contribution contract ──────────────────────
    # The bound `.value` is FORCED here. A fixture that only inspects the record's SHAPE passes while the
    # poison rides, because `poison` throws only when forced. What must survive the force is the gen-bind
    # `__configThunk` (resolved at the PRODUCING scope), never the raw poison.
    test-deferred-records-value-is-a-thunk-not-poison = {
      expr =
        let
          recs = (bindingsOf { gather = deferredGather; }).channels.ch;
          r = builtins.head (builtins.filter (c: c.deferred) recs);
        in
        {
          # attrNames FORCES the value: a raw poison ride aborts this expression outright.
          thunkKeys = builtins.attrNames r.value;
          resolvesAtProducingScope = r.value.__sourceScope != null;
          stillDeferred = r.deferred;
        };
      expected = {
        thunkKeys = [
          "__configThunk"
          "__fn"
          "__sourceScope"
        ];
        resolvesAtProducingScope = true;
        stillDeferred = true;
      };
    };

    # ── (3) SHADOW REFUSAL — the REGISTRATION origin, BOTH siblings ─────────────────────────────────────
    # A fleet registering a channel named `channels` aborts named, and so does one registering `settings` —
    # the SHIPPED sibling carries the identical hazard and was uncovered before this refusal, so covering
    # only the new one would leave the class half-guarded. Both fire at the FLEET grain ("fleet-wide"),
    # which is the `systems` forcing position: the subject is the registration, a defect of the fleet
    # before any consumer exists.
    test-registered-channel-named-channels-aborts-fleet-wide = {
      expr = builtins.deepSeq (bindingsOf {
        quirks = {
          ch = { };
          channels = { };
        };
      }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the registered channel `channels` is also the name of a binding SIBLING this surface appends at every node";
      };
    };
    test-registered-channel-named-settings-aborts-fleet-wide = {
      expr = builtins.deepSeq (bindingsOf {
        quirks = {
          ch = { };
          settings = { };
        };
      }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the registered channel `settings` is also the name of a binding SIBLING this surface appends at every node";
      };
    };

    # ── (4) SHADOW REFUSAL — the ENRICH-POLICY origin ───────────────────────────────────────────────────
    # A policy enriching a context key equal to a sibling name aborts at that node rather than having its
    # enrichment silently replaced. The assertion is that the abort NAMES THE ENRICHING POLICY
    # (`owners.<k>`) — not merely that it names the enrich origin: `owners` is what makes the remedy reach
    # a person, and an assertion satisfied by the label alone would pass against a message that says "an
    # enriching policy" and never says which.
    test-enrich-policy-shadow-names-the-policy = {
      expr = builtins.deepSeq (bindingsOf {
        policies.writeChannelsKey = {
          emits = [ "enrich" ];
          fn = _ctx: [
            (d.enrich {
              key = "channels";
              value = "enriched";
            })
          ];
        };
      }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "a context key enriched by policy `writeChannelsKey`";
      };
    };

    # ── (5) SHADOW REFUSAL — the DECLS-WRITER origin ────────────────────────────────────────────────────
    # A key reaching `base` through `inherited-context` ALONE — written by neither an enrich policy nor a
    # channel registration. The fixture carries it as a `den.systemViews.<system>` entry because that is
    # one of the two writers the remedy names; a fixture using a framework dimension name would exercise a
    # key no author can rename, so the remedy it pinned would reach nobody. Without this arm, arm (4)
    # exercises only the `owners` SUB-DOMAIN of its operand — an arm per operand is not an arm per writer.
    test-systemview-decl-shadow-names-the-decls-writer-remedy = {
      expr = builtins.deepSeq (bindingsOf {
        systemViews.${system}.channels = "from-the-system-view";
      }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the `den.systemViews.<system>` attrset that carries it";
      };
    };
    # …and that it is attributed to the DECLS writer rather than to one of the other four origins.
    #
    # GRAIN: the NODE one, and the fleet check must be SILENT on this input — a `den.systemViews` key is
    # registered as no channel, so `collidingRegistered` is empty and the `systems` `seq` passes through.
    # That silence is half of what the pair discriminates: an implementation quantifying check 1 over the
    # wrong key set would abort here too, and an arm asserting only "aborts named" could not tell them
    # apart. The LABEL is split from the REMEDY across the two arms because they fail for different
    # reasons: the remedy arm dies if the message stops reaching the writer, this one dies if the message
    # reaches them under the wrong diagnosis.
    #
    # ★ SINGLE-ORIGIN-SHAPED, and deliberately so: the leading `is ` renders only while the inherited
    # origin is this key's SOLE origin. On a key of arity two the same clause renders
    # `… and a scope-inherited declaration key …` and this assertion FAILS. That is why the join arms
    # below build their own multi-origin fleet instead of adding an origin here — the sensitivity is the
    # arm's, not the render's, and it is worth keeping: the arm is what says this fleet stayed
    # single-origin.
    test-systemview-decl-shadow-labels-the-inherited-origin = {
      expr = builtins.deepSeq (bindingsOf {
        systemViews.${system}.channels = "from-the-system-view";
      }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "is a scope-inherited declaration key AND the name of a binding SIBLING";
      };
    };

    # ── (6) SHADOW REFUSAL — the GATHERED-SURFACE origin ────────────────────────────────────────────────
    # A `den.channelGather` supplier returning a key equal to a sibling name. The assertion is on the
    # REMEDY SUBSTRING, because a message quantified over the wrong domain fires on this input too and
    # simply tells the wrong owner what to do; an assertion that it merely aborts passes against exactly
    # that defect.
    test-gathered-key-shadow-names-the-supplier-remedy = {
      expr = builtins.deepSeq (bindingsOf { gather = shadowGather; }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "rename the gathered key at its supplier";
      };
    };
    # It fires at the NODE grain, not the fleet one: the gathered key is registered as no channel, so
    # check 1's predicate (`elem k channelNames`) is false and only check 2 has this input in its domain.
    #
    # GRAIN, stated because the escalation pair below rests on it: the observable is check 2's
    # NODE-BEARING text, and the node is the discriminator. Check 1 names no node — its predicate has none
    # — so an arm satisfied by "aborts named" would be satisfied by either check, and the two-fleet pair
    # that measures the escalation would then be comparing an abort against itself. Asserting `unit:u1`
    # inside the pinned substring is what makes this arm the "before" endpoint rather than a duplicate of
    # arm (3).
    test-gathered-key-shadow-is-the-per-node-refusal = {
      expr = builtins.deepSeq (bindingsOf { gather = shadowGather; }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the binding key `channels` at `unit:u1` is a gathered channel-surface key";
      };
    };
    # THE REMEDY LAW, executable: each remedy must strictly SHRINK the origin set and never grow it (the
    # rendered SET, followed in full, is what falsifies the predicate — per-remedy falsification is
    # unsatisfiable on a multi-origin key). "Register it as a channel" is therefore NOT a remedy and must
    # not appear: it removes the key from nothing and ADDS the registration origin, so this refusal still
    # fires with one more origin and the FLEET check now fires too. Following it, the author is told they
    # made progress while the collision escalates.
    #
    # THE ASSERTION IS THE ABSENCE, which needs an instrument that can see one. `expectedError.msg` is
    # matched as an ECMAScript REGULAR EXPRESSION (`std::regex_search`), so the exclusion is written as a
    # negative lookahead over the whole message and paired with the one remedy that IS admissible — the
    # pairing is what stops the arm passing on a message that says nothing at all.
    #
    # The excluded token is `den.quirks`, not the one spelling "register it as a channel". Any remedy that
    # told this author to register the key must name the registration surface, so the token covers every
    # spelling of the non-remedy rather than the one a reader thought to enumerate; it also
    # excludes `registeredChannelOrigin`'s own remedy, which must not render here because a gathered key
    # carries no registration origin. NON-VACUITY, same instrument same run: `den.quirks` IS present in
    # the renders arm (3) and arm (6a) pin, so this suite exhibits both verdicts on the same
    # predicate — the lookahead is not one that could never have matched.
    test-gathered-key-shadow-does-not-offer-registration = {
      expr = builtins.deepSeq (bindingsOf { gather = shadowGather; }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*den\\.quirks)[\\s\\S]*rename the gathered key at its supplier";
      };
    };

    # ── (6a) THE ESCALATION, as a TRANSITION between two fleets ─────────────────────────────────────────
    # "Registering the gathered key ESCALATES to the fleet check" is a claim about a transition, and one
    # endpoint is not a transition. A boolean over a single fleet states neither endpoint: drop the gather
    # and the abort is arm (3)'s, which that arm already pins by message; drop the registration and
    # the abort is the per-node one arm (6) already pins. A bare `tryEval` cannot tell those two apart
    # — which is why both endpoints are asserted by MESSAGE.
    #
    # BEFORE — `test-gathered-key-shadow-is-the-per-node-refusal`: the gather-only fleet renders check 2's
    #          NODE-bearing text.
    # AFTER  — the two arms here, on that same fleet PLUS the `channels` registration.
    #
    # And the control the obvious repair reaches for does not exist: no mutation of the GATHER can flip
    # this fleet's verdict, because check 1's predicate tests the sibling names for membership of
    # `channelNames` and reads nothing any gather writes. A fleet that stops aborting once the gather is
    # removed is an input this construction cannot produce, so the discharge is a PAIR OF GRAINS rather
    # than a mutation control.
    test-registered-and-gathered-fleet-escalates-to-the-fleet-check = {
      expr = builtins.deepSeq registeredAndGathered "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the registered channel `channels` is also the name of a binding SIBLING this surface appends at every node";
      };
    };
    # THE NEGATIVE HALF, and it is the half the boolean could never say: check 1 PREEMPTS check 2, so on
    # this fleet the gathered-origin text does not render AT ALL. A message is one string, so this is a
    # real exclusion and not a restatement of the arm above — check 1's forcing position is the `seq` on
    # `systems`, ahead of `bindingsAt` on the output path, and the per-node witness list is never built.
    #
    # The two arms do not telescope: this one pins `fleet-wide` (a check-1 token the arm above does not
    # assert) under the exclusion, so either can fail while the other passes. If the clause wording drifts
    # the arm above dies and this one survives; if both checks ever render, this one dies and the arm
    # above survives.
    test-registered-and-gathered-fleet-withholds-the-per-node-text = {
      expr = builtins.deepSeq registeredAndGathered "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*is a gathered channel-surface key)[\\s\\S]*fleet-wide";
      };
    };

    # ── (7) THE FOUR JOINS — the separators, each asserted by a substring that SPANS it ──────────────────
    # A stated render that no arm asserts is an unmeasured render. Each of the four joins is a separate
    # expression in `errors.nix`, and every arm above pins text lying strictly INSIDE one clause of one
    # origin — so each separator could be replaced by any other string, or dropped, and no arm above would
    # move. The near-miss to not count as coverage: `AND the name of a binding SIBLING` is the message
    # TEMPLATE's own literal sitting between the label clause and the sibling clause, not
    # `renderOriginLabels`' `" and "`, which appears only BETWEEN TWO LABELS.
    #
    # Every substring below is metacharacter-free apart from `.`, which matches its own literal — a
    # requirement, not a coincidence, because `expectedError.msg` is a REGULAR EXPRESSION. Check 1's
    # "Rename the channel" clause, which wraps the registration path in PARENTHESES, sits in the same
    # render and cannot be pinned as written: the parentheses would be read as a group.

    # LABELS — `renderOriginLabels`' `" and "`, between the enriching-policy label and the inherited one.
    # Reachable only at origin arity ≥ 2, which is the case the five-way origin split exists to serve and
    # the case no other arm in this file exercises.
    test-multi-origin-render-joins-the-origin-labels = {
      expr = builtins.deepSeq multiOrigin "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "enriched by policy `writeChannelsKey` and a scope-inherited declaration key";
      };
    };
    # REMEDIES — `renderOriginRemedies`' `"; "`. The substring spans the boundary between the policy
    # remedy and the decls-writer remedy, so it dies if the two are ever concatenated without a separator
    # or if either is dropped. The remedy SET is what the law quantifies over: on a multi-origin key no
    # single remedy falsifies the predicate, so a message that emits one of two is a message that fails
    # open.
    test-multi-origin-render-joins-the-origin-remedies = {
      expr = builtins.deepSeq multiOrigin "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "writes; rename it where it is written";
      };
    };
    # SIBLINGS — `renderSiblings`' `", "`. The names come from `attrNames siblingBuilders`, so the order
    # is SORTED and not the order the attrset is written in; pinning the rendered order is what makes a
    # third sibling visible here rather than silently absorbed.
    test-multi-origin-render-joins-the-sibling-names = {
      expr = builtins.deepSeq multiOrigin "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "The sibling names are channels, settings.";
      };
    };
    # CLAUSES — the per-witness `" "` in check 1's fold, and the only join `multiOrigin` cannot reach: a
    # one-witness message has no clause boundary. The substring straddles the end of the first clause and
    # the start of the second, so it fails the day the fold names one of two colliding siblings — which is
    # how the owner of the other is never told.
    test-two-registered-siblings-render-joins-the-clauses = {
      expr = builtins.deepSeq twoRegisteredSiblings "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "channels, settings. the registered channel `settings` is also";
      };
    };

    # ── THE NON-VACUITY CONTROL, same instrument same run ───────────────────────────────────────────────
    # The fleet differing ONLY in the colliding name resolves clean and binds both surfaces. Without this,
    # every arm above is satisfied by a fixture that aborts for an unrelated reason — and an arm whose
    # fleet could never have evaluated records no coverage at all.
    test-control-non-colliding-fleet-resolves = {
      expr =
        let
          b = bindingsOf {
            gather =
              _dbn: _result: id:
              if id == "unit:u1" then
                {
                  notASibling = [
                    {
                      deferred = false;
                      value = "gathered-shadow";
                    }
                  ];
                }
              else
                { };
            policies.writeSomeOtherKey = {
              emits = [ "enrich" ];
              fn = _ctx: [
                (d.enrich {
                  key = "notASiblingEither";
                  value = "enriched";
                })
              ];
            };
            systemViews.${system}.stillNotASibling = "from-the-system-view";
          };
        in
        {
          flat = b.ch;
          gathered = b.notASibling;
          recordsSiblingPresent = b ? channels;
          settingsSiblingPresent = b ? settings;
        };
      expected = {
        flat = [ { dir = "d1"; } ];
        gathered = [ "gathered-shadow" ];
        recordsSiblingPresent = true;
        settingsSiblingPresent = true;
      };
    };
  };
}
