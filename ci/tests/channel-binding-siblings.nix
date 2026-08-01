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

  # The abort text, or a sentinel if the expression did NOT abort. `tryEval` carries no message channel, so
  # the message is pinned through `expectedError` on the arms below and this helper is used only where an
  # arm must assert a message does NOT say something.
  aborts = x: !(builtins.tryEval (builtins.deepSeq x x)).success;
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
    test-gathered-key-shadow-is-the-per-node-refusal = {
      expr = builtins.deepSeq (bindingsOf { gather = shadowGather; }) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "the binding key `channels` at `unit:u1` is a gathered channel-surface key";
      };
    };
    # THE REMEDY LAW, executable: a remedy is admissible only if following it makes the refusal's own
    # predicate FALSE. "Register it as a channel" is therefore NOT a remedy and must not appear — it
    # removes the key from nothing, so this refusal still fires with one MORE origin and the FLEET check
    # now fires too. Following it, the author is told they made progress while the collision escalates.
    test-gathered-key-shadow-does-not-offer-registration = {
      expr =
        let
          r = builtins.tryEval (builtins.deepSeq (bindingsOf { gather = shadowGather; }) "unreached");
        in
        {
          aborted = !r.success;
          # the ESCALATION, exhibited rather than asserted: registering the gathered key trips the FLEET
          # check, which the per-node abort alone did not.
          registeringEscalatesToTheFleetCheck = aborts (bindingsOf {
            quirks = {
              ch = { };
              channels = { };
            };
            gather = shadowGather;
          });
        };
      expected = {
        aborted = true;
        registeringEscalatesToTheFleetCheck = true;
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
