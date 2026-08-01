# THE AUTHORED-`selects` SEAM, stated per compat derivation arm.
#
# DECLARATION BEATS DERIVATION. A compat arm derives a rule's `selects` by TRANSLATING what a v1-shaped
# record states elsewhere — its placement for the schema and kind-include arms, its required entity-kind
# formals for the aspect-include arms. Where the record states a selection DIRECTLY, the translation must
# not overrule the thing it translates. Before this seam exactly one of five derivation arms asked, and a
# v1-shaped record could reach the required-and-total `selects` surface with an authored selection through
# that one arm alone.
#
# ★ ABSENCE MEANS SOMETHING DIFFERENT HERE THAN AT THE KERNEL SURFACE, which is why the seam introduces no
# default. A native author omitting `selects` has left the selection UNDECIDED, and the kernel refuses
# that. A v1-shaped record carrying no `selects` has stated no selection IN THAT FIELD — it stated one by
# where it is attached — so the derived value is the written-down reading of what it did state. The seam
# distinguishes "v1 said nothing here, so den-hoag translates" from "the author said this"; it does not
# invent a third meaning for the absence.
#
# ★ THE POPULATION IS FIVE ARMS AND THE OBLIGATION IS THREE, and the two exemptions are ROWS here rather
# than omissions. The aspect-include BARE-FN arm has no record to carry a field, and the kind-include EDGE
# arm mints one rule FOR A KIND over N refs, so neither has "the source record" the law quantifies over.
# Both are asserted below, because a population member that cannot carry a property is recorded with its
# reason under this design's own standing treatment.
#
# ★ WHY EVERY ROW READS THE FLEET AND NOT THE COMPILED RECORD. `denCompat.compile` is applied to a raw
# decls attrset and does not expand `den.default.includes`, so a compiled-`selects` reading answers for
# the directly-authored placements and NOT for the one §6.1's row uses. Reading `resolved-aspects` per
# node goes through `mkDen`, which is the path every placement shares — so one instrument covers all of
# them and no row rests on a surface that cannot see its own fixture.
{ denCompat, denHoag, ... }:
let
  inherit (denHoag) sel;

  # A v1 include-effect body: it edges the `injected` aspect wherever the rule fires, so WHERE the rule
  # was selected is readable off which nodes resolve that aspect.
  recordWith =
    extra:
    {
      __isPolicy = true;
      name = "p";
      fn = _ctx: [
        {
          __policyEffect = "include";
          value = {
            name = "injected";
          };
        }
      ];
    }
    // extra;

  # ONE fleet, one record, one authored value; only WHERE the record is placed moves between arms.
  # `place`: "aspect" — an aspect's own `.includes` (the aspect-include RECORD arm)
  #          "default" — a top-level `den.default.includes` entry (the same arm, the corpus's route)
  #          "kind"    — `den.schema.<kind>.includes` (the kind-include POLICY arm)
  fleetAt =
    place: extra:
    let
      r = recordWith extra;
    in
    denCompat.mkDen [
      {
        den = {
          hosts.x86_64-linux.h1 = {
            class = "nixos";
            users.u1 = { };
          };
          schema.user.parent = "host";
          aspects.injected.nixos.tag = "injected";
          aspects.a = {
            nixos.tag = "t";
            includes = if place == "aspect" then [ r ] else [ ];
          };
          schema.host.includes = [ "a" ] ++ (if place == "kind" then [ r ] else [ ]);
          schema.user.includes = [ ];
          default.includes = if place == "default" then [ r ] else [ ];
        };
      }
    ];

  aspectsAt =
    fleet: id:
    let
      e = fleet.den.structural.eval;
    in
    if e.allNodes ? ${id} then
      builtins.sort (a: b: a < b) (map (n: n.key) (e.get id "resolved-aspects"))
    else
      [ "<no-such-node>" ];
  # WHERE THE RULE LANDED, at the fleet's two nodes. The host is where every derived value below puts it;
  # the cell is where the authored value moves it, so the pair is what discriminates.
  landedAt =
    place: extra:
    let
      f = fleetAt place extra;
    in
    {
      host = aspectsAt f "host:h1";
      cell = aspectsAt f "user:u1@host:h1";
    };
  authored = sel.attrs { type = "user"; };

  # The kind-include POLICY arm with `den.schema.host.excludes` naming the record — the ONE fixture both
  # exclusion rows read, so the pair differs in exactly what the record states and in nothing else.
  excludedSelects =
    extra:
    let
      r = recordWith extra;
    in
    (denCompat.compile {
      hosts.x86_64-linux.h1.class = "nixos";
      aspects.a.nixos.tag = "t";
      schema.host = {
        includes = [
          "a"
          r
        ];
        # ★ A REF, not a bare name. `excludes` is matched through the same ref expansion the includes
        #   lists use, which reads `.name` off each entry — so a bare `"p"` here silently excludes
        #   nothing. Measured while building this row, and stated so the fixture is not read as evidence
        #   that the string form works.
        excludes = [ { name = "p"; } ];
      };
    }).policies.__kindInclude__host__policy__0.selects;
in
{
  flake.tests.compat-authored-selects = {
    # ARM — the aspect-include RECORD arm, at BOTH the routes that reach it. The derived value is the
    # record's `{ host, … }`-free formals widened by the arm's own confinement, which lands it at the
    # host; an authored `sel.attrs { type = "user"; }` moves it to the cell and off the host. The
    # `derived` rows are the byte-identity controls: the arm's answer with no authored field is exactly
    # what it was, so the seam adds a consultation and not a default.
    test-aspect-include-record-arm-honours-an-authored-selects = {
      expr = {
        derivedViaAspectIncludes = landedAt "aspect" { };
        authoredViaAspectIncludes = landedAt "aspect" { selects = authored; };
        # ★ the route §6.1's row actually uses — a top-level `den.default.includes` record, which this
        #   same arm compiles. Asserted separately because it reaches the arm by a different walk.
        derivedViaDefaultIncludes = landedAt "default" { };
        authoredViaDefaultIncludes = landedAt "default" { selects = authored; };
      };
      expected = {
        derivedViaAspectIncludes = {
          host = [
            "a"
            "defaults"
            "injected"
          ];
          cell = [
            "defaults"
            "injected"
          ];
        };
        authoredViaAspectIncludes = {
          # the host no longer resolves it — the authored selection took the rule off this node…
          host = [
            "a"
            "defaults"
          ];
          # …and the cell still carries it, so the rule fired, it simply fired where it was told to.
          cell = [
            "defaults"
            "injected"
          ];
        };
        derivedViaDefaultIncludes = {
          host = [
            "a"
            "defaults"
            "injected"
          ];
          cell = [
            "defaults"
            "injected"
          ];
        };
        authoredViaDefaultIncludes = {
          host = [
            "a"
            "defaults"
          ];
          cell = [
            "defaults"
            "injected"
          ];
        };
      };
    };

    # ARM — the kind-include POLICY arm. Its derived value is `sel.attrs { type = <kind>; }`, the arm's
    # translation of WHERE the record is attached; an authored value replaces it. Read at the compiled
    # record as well as at the fleet, because this placement is authored directly and the compiled
    # surface can therefore see it — two instruments, one claim.
    test-kind-include-policy-arm-honours-an-authored-selects = {
      expr =
        let
          compiledOf =
            extra:
            let
              r = recordWith extra;
            in
            (denCompat.compile {
              hosts.x86_64-linux.h1 = {
                class = "nixos";
                users.u1 = { };
              };
              schema.user.parent = "host";
              aspects.injected.nixos.tag = "injected";
              aspects.a.nixos.tag = "t";
              schema.host.includes = [
                "a"
                r
              ];
            }).policies.__kindInclude__host__policy__0.selects;
        in
        {
          compiledDerived = compiledOf { };
          compiledAuthored = compiledOf { selects = authored; };
          derived = landedAt "kind" { };
          authoredWins = landedAt "kind" { selects = authored; };
        };
      expected = {
        compiledDerived = sel.attrs { type = "host"; };
        compiledAuthored = sel.attrs { type = "user"; };
        derived = {
          host = [
            "a"
            "defaults"
            "injected"
          ];
          # ★ the cell does NOT carry it under the derived value, and that is the arm's confinement
          #   doing its job: `sel.attrs { type = "host"; }` is the whole of what this arm derives.
          cell = [ "defaults" ];
        };
        authoredWins = {
          host = [
            "a"
            "defaults"
          ];
          cell = [
            "defaults"
            "injected"
          ];
        };
      };
    };

    # THE EXCLUSION WORKING NORMALLY — the control, and the half of this pair whose answer must NOT move.
    # A record that states no selection of its own leaves `den.schema.host.excludes` the only statement
    # about where it fires, and that statement is honoured exactly as it was before the seam existed:
    # `sel.any [ ]`. Nothing about refusing the CONFLICT below may disturb the non-conflicting case.
    test-an-excluded-kind-include-policy-with-no-authored-selects-selects-nothing = {
      expr = excludedSelects { };
      expected = sel.any [ ];
    };

    # ★★ TWO AUTHORED STATEMENTS IN CONFLICT ARE REFUSED, NAMED, AT THE ARM. `den.schema.host.excludes`
    # naming `p` states that `p` is not selected at `host`; `p`'s own `selects` states where it IS
    # selected. BOTH are authored — an exclude is a DECLARATION made at the schema rather than on the
    # record, not a derivation — so the law that orders a record above a DERIVATION is silent here, and
    # reading it as though it spoke would install a precedence without an argument. Every ordering
    # honours one authored statement and makes the other DISAPPEAR with no signal, which is the defect
    # class this whole surface exists to remove; so the conflict is made unrepresentable instead of
    # silently resolved. The message names the policy, the kind, both statements and the fix, so the
    # author is told which two statements collided rather than being handed one of them.
    #
    # ★ THE REFUSAL IS ON THE CONFLICT OF STATEMENTS, NOT OF OUTCOMES. This fixture's authored value
    # disagrees with the exclusion, but an authored `sel.any [ ]` that AGREED with it would refuse just
    # the same — noticing the agreement would need selector equality, which this arm declines to rest on.
    test-an-excluded-kind-include-policy-with-an-authored-selects-refuses = {
      expr = excludedSelects { selects = authored; };
      expectedError = {
        type = "ThrownError";
        msg = "policy `p` carries an authored `selects` AND is named by `den\\.schema\\.host\\.excludes`.*DROP ONE";
      };
    };

    # THE TWO STATED NON-SEAMS, executed rather than argued.
    test-the-two-arms-that-owe-no-seam = {
      expr = {
        # The aspect-include BARE-FN arm's source is a FUNCTION. A consultation there is TOTAL but
        # VACUOUS — it answers `false` on every input the arm can receive — so it would be a constant
        # and not a seam. Executed, with both directions of the control.
        functionCarriesNoField = (x: x) ? selects;
        ctlRecordWithTheFieldAnswersTrue = { selects = 1; } ? selects;
        ctlRecordWithoutItAnswersFalse = { } ? selects;
        # The kind-include EDGE arm mints ONE rule FOR THE KIND over N refs, so there is no "the source
        # record" to ask. Its selector is not a derivation FROM a source — it is the statement THAT a
        # kind's own edge rule fires at that kind's nodes.
        edgeRuleSelectsItsKind =
          (denCompat.compile {
            hosts.x86_64-linux.h1.class = "nixos";
            aspects.a.nixos.tag = "t";
            schema.host.includes = [ "a" ];
          }).policies.__kindInclude__host.selects;
      };
      expected = {
        functionCarriesNoField = false;
        ctlRecordWithTheFieldAnswersTrue = true;
        ctlRecordWithoutItAnswersFalse = false;
        edgeRuleSelectsItsKind = sel.attrs { type = "host"; };
      };
    };
  };
}
