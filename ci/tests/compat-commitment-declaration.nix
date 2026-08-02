# THE COMMITMENT DECLARATION LAWS — which route a pipe's data takes is DECLARED, and every route that a
# declaration does not authorise is refused BY NAME rather than dropped.
#
# `pipeOp` split into two kinds. `pipeCommit` is the FLEET compose commitment (a derived-channel DAG, a
# delivery route, an aspect-delivery target); it rides the record's `ops` field, built by ONE
# definition-time firing at the mint. `pipeMark` is the per-node SITE MARK (append/expose/broadcast/
# collect); it rides the DISPATCHED body's emission. The translation mode picks the kind at compile time
# and never reads a ctx to do it.
#
# THE REFUSALS COME IN A UNION OF TWO LAWS OVER EMISSION SITES, not a partition of policies — `markFn` is
# applied at exactly two places, so every unauthorised commitment it can emit is emitted at one of them:
#
#   • LAW (a), the RECOVERY fire — reached only by a policy with NO declaration, so any `pipeCommit` among
#     the recovered declarations is unauthorised by construction. Raised from the RETURNED declarations,
#     outside `classifyDecls`' `tryEval` envelope (which destroys a caught throw's text) and BEFORE the
#     `unique (map kindOf …)` projection (which erases the channel and the commitment fields the message
#     names). It is the shim's refusal and carries the shim's prefix.
#   • LAW (b), DISPATCH — the kernel's general codomain law at `conformingProduce`. It carries the KERNEL
#     prefix and has no field clause to render, so an arm asserting only "aborts by name" would pass on
#     either law and witness neither position. Both arms below therefore pin the field clause — one
#     requiring it, one EXCLUDING it — and the pair exhibits both verdicts of one predicate in one run.
#
# AN UNDECLARED POLICY CAN TAKE EITHER, which is why the union is checkable rather than merely argued: it
# takes (a) iff its sentinel firing actually yields a commitment, and a ctx-conditional body's does not.
# The three `condCommit` arms are one body exhibiting the empty head, the reason the head is empty, and
# law (b) at a real node.
#
# ★ EVERY EXCLUSION HERE IS PROVED LIVE BY EXHIBITION. Each of the four negative lookaheads, re-pointed at
# text the SAME message does carry, reddens exactly its own arm and no other. An exclusion that could never
# have matched is a green that measures nothing, and a bare exclusion with no conjoined positive would pass
# on a message that says nothing at all — so each is paired with a substring the message must render.
#
# ★ THE EMPTY HEAD IS PINNED AS A VALUE, NOT AS AN ABSENCE. The conditional reads `host.class` — a
# `probe-sentinel.nix` CONSTANT, so the value sentinel answers `"«sentinel»"` and the body reaches a
# genuine non-matching value rather than an `or`-defaulted hole. Its control is the same body with the
# condition inverted to match that constant: the recovery then yields the commitment and law (a) fires. A
# fixture pinning an absence would hold for any field the sentinel omits and would say nothing about the
# mechanism that is actually running.
{ denHoag, denCompat, ... }:
let
  inherit (denHoag) sel;
  d = denHoag.declare;
  msg = denHoag.internal.policyMessage;
  p = denCompat.pipe;

  optionals = c: xs: if c then xs else [ ];
  bothKinds = [
    "pipeCommit"
    "pipeMark"
  ];

  # ── the fleet: two nixos hosts (mutual siblings) on one registered channel ───────────────────────────
  # Siblings, so a `collect` mark's effect is visible in a binding: h1 gaining h2's contribution is the
  # per-node evidence that a mark DISPATCHED, which no read of a compiled record can give.
  v1 = policies: {
    inherit policies;
    hosts.x86_64-linux.h1 = {
      class = "nixos";
    };
    hosts.x86_64-linux.h2 = {
      class = "nixos";
    };
    quirks.mesh = { };
    aspects.hemit =
      { host, ... }:
      {
        mesh = [ "mesh-${host.name}" ];
        nixos.networking.hostName = host.name;
      };
    schema.host.includes = [ "hemit" ];
  };
  compiled = policies: (denCompat.compileFull (v1 policies)).policies;
  fleetOf = policies: denCompat.mkDen [ { config.den = v1 policies; } ];
  bindOf = policies: id: (fleetOf policies).den.output.systems.nixos.${id}.bindings;
  channelsOf =
    policies: builtins.sort (a: b: a < b) (builtins.attrNames (fleetOf policies).den.quirkDag.channels);
  # the declaration kinds a REAL node received, which is the dispatched firing's own output.
  dispatchedKindsAt =
    policies: id:
    map (a: a.__action or null) (
      ((fleetOf policies).den.structural.eval.get id "declarations").actions.collection or [ ]
    );

  # ── the bodies ──────────────────────────────────────────────────────────────────────────────────────
  # A MIXED record: one deriving stage (the commitment) and one site mark. Both kinds are declared, so the
  # commitment rides `ops` and the mark route emits `pipeMark` alone.
  mixedBody = _ctx: [
    (p.from "mesh" [
      (p.transform (x: x))
      (p.collect ({ host, ... }: true))
    ])
  ];
  # A8's NARROWING subject: a `to` target and a site mark, NO route and NO deriving stage. `isSiteMarkData`
  # said nothing about `targeted`, so this record is legal today; `bearsCommitment` is true for it.
  narrowBody = _ctx: [
    (p.from "mesh" [
      (p.to [ "hemit" ])
      (p.collect ({ host, ... }: true))
    ])
  ];
  # A8's WIDENING subject: no marks, no derived, no routes, no targets. `isSiteMarkData`'s `marks != [ ]`
  # term aborted it today; a pipe that states nothing is an empty statement, not an error.
  emptyBody = _ctx: [ (p.from "mesh" [ ]) ];
  # A7's subject: two same-shaped deriving declarations in ONE policy on ONE channel.
  twoPipesBody = _ctx: [
    (p.from "mesh" [ (p.transform (x: x)) ])
    (p.from "mesh" [ (p.transform (x: x)) ])
  ];
  # A9-undeclared's subject: a commitment-bearing body on a policy with NO declared codomain. `selects` is
  # declared because the policy is registered and included nowhere — an undeclared SELECTION is derived
  # from the schema, where "in no includes list" means "selects nothing", which is the right answer to a
  # question these arms are not asking.
  undeclaredCommit = {
    __isPolicy = true;
    selects = sel.star;
    fn = _ctx: [ (p.from "mesh" [ (p.transform (x: x)) ]) ];
  };
  # A9-undeclared-CONDITIONAL: the same shape behind a ctx condition on a sentinel CONSTANT.
  condOn = match: {
    __isPolicy = true;
    selects = sel.star;
    fn =
      { host, ... }:
      optionals (host.class == match) [ (p.from "mesh" [ (p.transform (x: x)) ]) ];
  };

  policyWith = emits: fn: {
    __isPolicy = true;
    selects = sel.star;
    inherit emits fn;
  };

  # ── A10's subject: a NATIVE record's `ops` field, validated at REGISTRATION ──────────────────────────
  # `policyMessage` returns its verdict as a VALUE (`null` = clean), so the refusal TEXT is asserted
  # directly rather than through an error channel — Nix cannot recover a caught throw's text.
  registers =
    ops:
    msg {
      P = {
        emits = [ "pipeCommit" ];
        selects = sel.star;
        fn = _: [ ];
        inherit ops;
      };
    };

  # ── A2's subject: a NATIVE body emitting a commitment declaration ────────────────────────────────────
  nativeCommit = d.pipeCommit {
    channel = "mesh";
    derived = {
      __derived = true;
    };
    routes = [ ];
    targeted = [ ];
  };
  nativeFleet =
    emits:
    denHoag.mkDen [
      {
        config.den.schema.node.parent = null;
        config.den.node.h = { };
        config.den.policies.emitsCommit = {
          inherit emits;
          selects = sel.star;
          fn = _: [ nativeCommit ];
        };
      }
    ];
in
{
  flake.tests.compat-commitment-declaration = {
    # ── A2 — the guard replacement, at the KERNEL ─────────────────────────────────────────────────────
    # The retired `errors.opsInBody` sat at `conformingProduce` and refused a body-emitted commitment by a
    # VALUE-SHAPE test. Its replacement is the general codomain law two lines above it: routing is now the
    # DECLARED kind, so an unauthorised commitment fails `admitted ? pipeCommit` like any other undeclared
    # kind. It stands where a stratum-order fixture would have: `errors.mixedStratum` is unraisable
    # (`checkStratum` has no call site), so a fixture asserting a stratum abort asserts something the tree
    # cannot produce. This one asserts the abort the tree actually reaches.
    #
    # ★ Asserted on the NATIVE surface, and the lookahead is what makes that an assertion: the refusal
    # carries the KERNEL prefix, so no shim message can satisfy it. Non-vacuity, same instrument same run:
    # the law-(a) arms below are green on messages that DO carry `den-compat`.
    test-a2-native-body-commitment-under-a-mark-only-codomain-aborts = {
      expr = builtins.deepSeq ((nativeFleet [ "pipeMark" ]).den.structural.eval.get "node:h"
        "declarations"
      ) "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*den-compat)[\\s\\S]*den-hoag: declaration codomain: policy `emitsCommit` produced a `pipeCommit` declaration, which is not in its declared `emits` = \\[ pipeMark \\]";
      };
    };

    # ── A4 — the two emitted kind sets are DISJOINT on the declared branch ────────────────────────────
    # Asserted on the KIND SETS, not on a filter's output: the invariant is conditional on the declaration
    # authorising the commitment, so `markFn` takes the `declaresCommit`-true branch and emits `pipeMark`
    # alone. A fixture asserting UNCONDITIONAL disjointness would pass here and forbid A9-undeclared,
    # where the two kinds are deliberately not disjoint.
    #
    # The FIELD partition rides with it, because it is what the two kinds mean: `channel` is the join key
    # and rides both; `derived`/`routes`/`targeted` ride the commitment; `marks` rides the mark.
    test-a4-declared-branch-kind-sets-are-disjoint = {
      expr =
        let
          r = (compiled { mixed = policyWith bothKinds mixedBody; }).mixed;
        in
        {
          commitKinds = map (a: a.__action) r.ops;
          dispatchedKinds = dispatchedKindsAt { mixed = policyWith bothKinds mixedBody; } "host:h1";
          commitFields = map builtins.attrNames r.ops;
          dispatchedFields = map builtins.attrNames (r.fn { });
        };
      expected = {
        commitKinds = [ "pipeCommit" ];
        dispatchedKinds = [ "pipeMark" ];
        commitFields = [
          [
            "__action"
            "channel"
            "derived"
            "routes"
            "targeted"
          ]
        ];
        dispatchedFields = [
          [
            "__action"
            "channel"
            "marks"
          ]
        ];
      };
    };

    # ── A5 — a mark-only policy reading a per-node coordinate in a SITE-MARK predicate ────────────────
    # It fires per node at the FULL ctx, seeds nothing, and aborts nowhere. The discriminator is that the
    # coordinate decides the mark PER NODE: h1 carries the collect and gathers its sibling, h2 carries no
    # mark and binds its own emission alone. Under a naive blanket ctx narrowing both nodes would answer
    # the same way, which is the guard this arm is.
    test-a5-mark-only-policy-fires-per-node-at-the-full-ctx = {
      expr =
        let
          pol = {
            meshCollect = policyWith [ "pipeMark" ] (
              { host, ... }:
              optionals (host.name == "h1") [
                (p.from "mesh" [ (p.collect ({ host, ... }: true)) ])
              ]
            );
          };
        in
        {
          h1 = (bindOf pol "host:h1").mesh;
          h2 = (bindOf pol "host:h2").mesh;
          seeds = (compiled pol).meshCollect.ops;
        };
      expected = {
        h1 = [
          "mesh-h1"
          "mesh-h2"
        ];
        h2 = [ "mesh-h2" ];
        seeds = [ ];
      };
    };

    # ── A7 — the declaration-site token ───────────────────────────────────────────────────────────────
    # Two same-shaped deriving declarations in one policy on one channel get DISTINCT derived ids (gen-pipe
    # L12a's collision class, which a shared base+op would otherwise collapse), and the same policy
    # compiled twice gets IDENTICAL ones. Injectivity and STABILITY are different properties and the
    # design rests on the second: the token is produced by a firing that happens ONCE, so it cannot vary
    # across firings that do not happen. The ordinal is taken within `(policyId, pipeName)`, so an
    # unrelated effect added to the body renumbers nothing.
    test-a7-derived-channel-ids-are-distinct-and-stable = {
      expr =
        let
          idsOf =
            c: map (o: o.derived.id) (compiled { twoPipes = policyWith bothKinds twoPipesBody; }).twoPipes.ops;
        in
        {
          ids = idsOf null;
          stable = idsOf 1 == idsOf 2;
        };
      expected = {
        ids = [
          "mesh.over#twoPipes-mesh-0.map"
          "mesh.over#twoPipes-mesh-1.map"
        ];
        stable = true;
      };
    };

    # ── A8-widening — a markless, commitmentless pipe is LEGAL ────────────────────────────────────────
    # `isSiteMarkData`'s second term is `marks != [ ]`, so this record aborts at `errors.opsInBody` today.
    # `bearsCommitment` is false for it, so it compiles to a mark carrying nothing — the same empty-head
    # reading the tree already applies to `emits = [ ]`, one level down.
    #
    # ★ IT IS ALSO THE REGRESSION TEST FOR `bearsCommitment`'s THIRD DISJUNCT, and the kill is measured
    # rather than argued. `compilePipe` ALWAYS binds `targeted` as a list, so a disjunct written
    # `(a.targeted or null) != null` is constant-true over every record it can build. Mutating the shipped
    # `(a.targeted or [ ]) != [ ]` to that form reddens exactly two arms of this suite — this one and
    # `test-a5-…`, the two whose records are pure site marks under a mark-only declaration, which is
    # precisely the population the tautology mis-classifies. Every other arm holds, because a declared
    # commitment takes the `declaresCommit` branch regardless of what the predicate says.
    test-a8-widening-markless-commitmentless-pipe-is-legal = {
      expr =
        let
          pol = {
            emptyPipe = policyWith [ "pipeMark" ] emptyBody;
          };
          r = (compiled pol).emptyPipe;
        in
        {
          seeds = r.ops;
          dispatched = r.fn { };
          atTheNode = dispatchedKindsAt pol "host:h1";
        };
      expected = {
        seeds = [ ];
        dispatched = [
          {
            __action = "pipeMark";
            channel = "mesh";
            marks = [ ];
          }
        ];
        atTheNode = [ "pipeMark" ];
      };
    };

    # ── A8-narrowing — a `to` target beside a site mark is REFUSED without the commitment declaration ──
    # Legal today (the four terms of `isSiteMarkData` say nothing about `targeted`), refused here: the
    # record bears a commitment, the declaration does not authorise it, and the mark route emits the
    # commitment kind INTO THE PATH OF THE REFUSAL rather than dropping the target.
    #
    # ★ Both kinds are required, and this record is exactly where a `pipeCommit`-only declaration would be
    # fatal: it carries `marks` by construction, so under one kind it would abort on its own mark and the
    # fixture would fail for a reason that has nothing to do with `targeted`.
    test-a8-narrowing-target-plus-mark-needs-the-commitment-declaration = {
      expr = builtins.deepSeq (bindOf {
        narrow = policyWith [ "pipeMark" ] narrowBody;
      } "host:h1") "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "policy `narrow` produced a `pipeCommit` declaration, which is not in its declared `emits` = \\[ pipeMark \\]";
      };
    };
    # …and its COMPANION: the same record under both kinds compiles, lands the target on `ops`, and its
    # marks STILL DISPATCH. Asserting only that `ops` is populated would still pass if the mark route were
    # dropped, which is the half that makes each change a decision on the record rather than a discovery.
    test-a8-narrowing-companion-lands-the-target-and-still-dispatches-marks = {
      expr =
        let
          pol = {
            narrow = policyWith bothKinds narrowBody;
          };
          r = (compiled pol).narrow;
        in
        {
          seedKinds = map (a: a.__action) r.ops;
          targets = map (a: map (t: t.select) a.targeted) r.ops;
          dispatchedKinds = dispatchedKindsAt pol "host:h1";
          # the collect mark reached a real node: h1's binding carries its sibling's contribution
          gathered = (bindOf pol "host:h1").mesh;
        };
      expected = {
        seedKinds = [ "pipeCommit" ];
        targets = [ [ [ "hemit" ] ] ];
        dispatchedKinds = [ "pipeMark" ];
        gathered = [
          "mesh-h1"
          "mesh-h2"
        ];
      };
    };

    # ── A9-declared — LAW (b), and it has NO FIELD CLAUSE ─────────────────────────────────────────────
    # A declared codomain lacking `pipeCommit` is never recovered, so law (a) never sees this policy: it
    # reaches dispatch and the kernel's general conformance law refuses it. Declared ⇒ no recovery ⇒ no
    # envelope, which is exactly why this arm cannot witness the truncation law (a) was moved to avoid.
    #
    # ★ THE EXCLUSION IS THE ASSERTION. Law (b) names a kind and has nothing to say about WHICH commitment
    # field is populated; law (a) does. An arm asserting only "aborts by name" is satisfied by either.
    # Non-vacuity, same instrument same run: the law-(a) arm below is green on a message that DOES carry
    # `carrying a derived-channel DAG`, so both verdicts of this one predicate are exhibited in this run.
    test-a9-declared-law-b-names-the-kind-and-renders-no-field-clause = {
      expr = builtins.deepSeq (bindOf {
        declaredMarkOnly = policyWith [ "pipeMark" ] mixedBody;
      } "host:h1") "unreached";
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*carrying a derived-channel DAG)[\\s\\S]*policy `declaredMarkOnly` produced a `pipeCommit` declaration, which is not in its declared `emits`";
      };
    };

    # ── A9-undeclared — LAW (a), the most load-bearing arm of the set ─────────────────────────────────
    # The recovery SUCCEEDS, the returned declarations contain a `pipeCommit`, and the refusal fires inside
    # `recoverEmits` BEFORE the kind projection. Four elements are assertable and each pins a different
    # decision:
    #   • the prefix `den-compat: compose commitment:` — the SHIM's, which asserts the refusal lives in
    #     `lib/compat/errors.nix` and not in the kernel's. An arm pinning `den-hoag:` would assert the
    #     position did not move.
    #   • the CHANNEL, and
    #   • WHICH commitment field is populated — both erased by `unique (map kindOf …)`, so an arm asserting
    #     them is a regression test for the refusal's POSITION, not merely for it firing.
    #
    # ★ THE FIELD CLAUSE IS ASSERTED AS A COMPUTATION, NOT AS A CONSTANT. This record populates `derived`
    # alone, so the clause must render `derived` AND NOT the other two: an arm pinning the derived clause
    # by itself is equally satisfied by a message that names all three unconditionally, which is what
    # `commitmentFieldsOf`'s empty-render fallback does and what a hard-coded clause would do. The
    # exclusion is proved live by its own companion below, whose record populates two fields and whose
    # render carries the excluded text.
    test-a9-undeclared-law-a-names-the-channel-and-only-the-populated-field = {
      expr = (compiled { inherit undeclaredCommit; }).undeclaredCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*a delivery route)[\\s\\S]*den-compat: compose commitment: policy `undeclaredCommit` produced a `pipeCommit` declaration on channel `mesh` carrying a derived-channel DAG";
      };
    };
    # …and a record populating TWO fields renders BOTH, joined. This is the arm that makes the one above a
    # statement about `commitmentFieldsOf` rather than about one string: the two records differ by a single
    # `as` stage, and the clause the first arm EXCLUDES is the clause this one REQUIRES. The pinned
    # substring spans the join, so collapsing the separator moves exactly this arm.
    test-a9-undeclared-law-a-joins-two-populated-fields = {
      expr =
        (compiled {
          twoFields = {
            __isPolicy = true;
            selects = sel.star;
            fn = _ctx: [
              (p.from "mesh" [
                (p.transform (x: x))
                (p.as "sink")
              ])
            ];
          };
        }).twoFields.emits;
      expectedError = {
        type = "ThrownError";
        msg = "carrying a derived-channel DAG \\(`derived`\\) and a delivery route \\(`routes`\\)";
      };
    };
    # …and the REMEDY names BOTH kinds. An author following a `pipeCommit`-only remedy verbatim would clear
    # this abort and take law (b) at the first dispatched node — a refusal whose own remedy produces the
    # next refusal. The brackets are escaped because `expectedError.msg` is an ECMAScript regex, in which
    # an unescaped `[ … ]` is a character class and not the literal the message renders.
    test-a9-undeclared-law-a-remedy-names-both-kinds = {
      expr = (compiled { inherit undeclaredCommit; }).undeclaredCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "Declare this policy's codomain as `\\[ \"pipeCommit\" \"pipeMark\" \\]`";
      };
    };
    # …and it is NOT the recovery-failure message. Under a construction that raised this refusal from
    # INSIDE the body, `classifyDecls`' `tryEval` would catch it and render `policyCodomainUnrecoverable` —
    # policy name only, channel and field destroyed. The exclusion is what makes this arm discriminate the
    # position rather than restate the abort.
    test-a9-undeclared-law-a-is-not-the-recovery-failure-message = {
      expr = (compiled { inherit undeclaredCommit; }).undeclaredCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "^(?![\\s\\S]*could not determine the declaration codomain)[\\s\\S]*produced a `pipeCommit` declaration on channel `mesh`";
      };
    };

    # ── A9-undeclared-conditional — RE-EXPRESSED, and the movement is the point ───────────────────────
    #
    # ★★★ THESE THREE ARMS USED TO PIN THE DEFECT. `condCommit` reads `host.class`, so at the VALUE
    # sentinel its effect list evaluated to `[ ]`, the recovery returned an EMPTY HEAD, law (a) did not
    # fire, and the policy COMPILED — carrying a codomain the shim had invented from the sentinel's own
    # constant. The suite asserted all three steps, and the second one said so outright: the empty head
    # was "the sentinel's value". A fixture stating what the sentinel decided is a fixture pinning a
    # recovery that answers about the sentinel instead of about the body.
    #
    # THE CODOMAIN SPY REMOVES THE STEP THEY RESTED ON. The fire binds every coordinate field to a named
    # throw, so a body that BRANCHES on one is CAUGHT and REFUSED at compile — named, naming the
    # coordinate and the declaration that fixes it — instead of compiling on an invented empty head and
    # failing later at dispatch, or not failing at all.
    #
    # ★ THE UNION PROPERTY THE OLD ARMS EXISTED TO PROTECT IS NOT LOST, and it is not carried by these
    # three: law (a) has its witness at `test-a9-undeclared-law-a-names-the-channel-and-only-the-populated-field`
    # (an UNCONDITIONAL undeclared commitment, which the spy admits and law (a) then refuses) and law (b)
    # at `test-a9-declared-law-b-names-the-kind-and-renders-no-field-clause`. Both are in this run. What
    # these arms now pin is the THIRD state, which no fixture could reach before: refused for being
    # unanswerable, rather than answered wrongly.
    test-a9-undeclared-conditional-is-refused-by-name = {
      expr = (compiled { condCommit = condOn "nixos"; }).condCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "den-compat: policy codomain: v1 policy `condCommit` declares no codomain but no source declares emits";
      };
    };
    # …and the refusal names the COORDINATE it read and the REMEDY that fixes it, leaving the body alone.
    # ★ THE COORDINATE, NOT THE FIELD: the spy's own throw names `class`, but `tryEval` destroys a caught
    # throw's text, so what survives is the per-coordinate attribution loop's verdict — synthesized on the
    # caller's side of the boundary, exactly as `commitmentFireFailed` is.
    test-a9-undeclared-conditional-refusal-names-the-coordinate-and-the-remedy = {
      expr = (compiled { condCommit = condOn "nixos"; }).condCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "The coordinate\\(s\\) it reads: host[\\s\\S]*COMPLETE THE DECLARATION[\\s\\S]*den.policyCodomains.condCommit";
      };
    };
    # ★★ THE DISCRIMINATION, AND IT IS STRICTLY STRONGER THAN THE PAIR IT REPLACES. The same body with the
    # condition inverted to match the sentinel's OWN constant is refused IDENTICALLY. Under the value
    # sentinel these two inputs — differing in one string literal — produced OPPOSITE outcomes, because
    # the sentinel's constant decided which branch the recovery saw. The spy never lets a coordinate value
    # decide anything, so the verdict no longer depends on what the sentinel happens to carry. That
    # independence is the soundness claim, executable.
    test-a9-undeclared-conditional-verdict-does-not-depend-on-the-sentinel-constant = {
      expr = (compiled { condCommit = condOn "«sentinel»"; }).condCommit.emits;
      expectedError = {
        type = "ThrownError";
        msg = "den-compat: policy codomain: v1 policy `condCommit` declares no codomain but no source declares emits";
      };
    };

    # ── A9-control — the design ACCEPTING a legitimate commitment ─────────────────────────────────────
    # The same body under both kinds compiles, populates `ops`, threads the derived DAG into the ONE fleet
    # compose, AND its marks still dispatch. Asserting only `ops` would still pass if the mark route were
    # dropped; asserting only the marks would pass if the commitment never reached the compose. The
    # pipe-free fleet is the same-run control on both halves — no derived channel, no gathered sibling.
    test-a9-control-populates-ops-and-still-dispatches-its-marks = {
      expr =
        let
          pol = {
            controlBoth = policyWith bothKinds mixedBody;
          };
        in
        {
          seedKinds = map (a: a.__action) (compiled pol).controlBoth.ops;
          channels = channelsOf pol;
          h1 = (bindOf pol "host:h1").mesh;
          baseChannels = channelsOf { };
          baseH1 = (bindOf { } "host:h1").mesh;
        };
      expected = {
        seedKinds = [ "pipeCommit" ];
        channels = [
          "__den-demands"
          "mesh"
          "mesh.over.3"
          "mesh.over.3.map.2"
        ];
        h1 = [
          "mesh-h1"
          "mesh-h2"
        ];
        baseChannels = [
          "__den-demands"
          "mesh"
        ];
        baseH1 = [ "mesh-h1" ];
      };
    };
    # …and the SAME stamp reaches the INCLUDE path. A policy record nested in an aspect's `.includes` is
    # minted by `familyStamps` rather than `mintFleetWide`, and omitting the seam there would make it a
    # property of HOW a policy was wired rather than of what it declares — an include-path commitment
    # would be dropped from a seed that never received it, which is the class this seam closes. The site
    # token carries the synthetic key, which is what says the stamp came from this arm and not the other.
    test-a9-control-on-the-include-path-stamps-ops-too = {
      expr =
        let
          record = {
            __isPolicy = true;
            name = "includedCommit";
            emits = bothKinds;
            fn = _ctx: [ (p.from "mesh" [ (p.transform (x: x)) ]) ];
          };
          compiledInclude =
            (denCompat.compileFull (
              (v1 { })
              // {
                aspects.hemit =
                  { host, ... }:
                  {
                    mesh = [ "mesh-${host.name}" ];
                    nixos.networking.hostName = host.name;
                  };
                aspects.carrier.includes = [ record ];
                schema.host.includes = [
                  "hemit"
                  "carrier"
                ];
              }
            )).policies.__aspectInclude__includedCommit;
        in
        {
          seedKinds = map (a: a.__action) compiledInclude.ops;
          ids = map (a: a.derived.id) compiledInclude.ops;
        };
      expected = {
        seedKinds = [ "pipeCommit" ];
        ids = [ "mesh.over#__aspectInclude__includedCommit-mesh-0.map" ];
      };
    };

    # ── A10 — the registration `ops` law, over the DECLARED KIND ──────────────────────────────────────
    # `ops` carries fleet-wide compose commitments only, so every element must be a `pipeCommit`. Written
    # over `a.__action or null` and NOT over `declare.kindOf`: `kindOf` is a bare selection with no
    # default, so the tag-less element — the third arm, and exactly the payload nothing was checking after
    # the value-shape predicate retired — would raise Nix's own unattributed `attribute '__action'
    # missing` from inside the very predicate that exists to name it. The third arm is what discriminates
    # the law written over `__action` from the law written over `kindOf`, which cannot express it.
    test-a10-mark-element-in-ops-is-refused-as-per-node-data = {
      expr = registers [ { __action = "pipeMark"; } ];
      expected = "den.policies: `P`.ops carries a `pipeMark` - site marks are per-node emission data fired WHERE the policy fires, so they belong in the body's emission, not in the fleet-wide compose seed. `ops` carries only ctx-independent commitments (`pipeCommit`: a derived-channel DAG, a delivery route or an aspect-delivery target)";
    };
    # a STALE spelling — the retired kind name — is refused as an unknown ops element and names what it saw.
    test-a10-foreign-action-in-ops-is-an-unknown-element = {
      expr = registers [ { __action = "pipeOp"; } ];
      expected = "den.policies: `P`.ops carries an element whose `__action` is `pipeOp` - every `ops` element is a `pipeCommit` declaration. An element carrying another kind, or no readable `__action`, is not a compose commitment and nothing downstream can route it";
    };
    # …and NO `__action` at all takes the SAME named refusal, rendering the absence rather than dying on it.
    test-a10-tagless-element-in-ops-takes-the-same-named-refusal = {
      expr = registers [ { channel = "mesh"; } ];
      expected = "den.policies: `P`.ops carries an element whose `__action` is `«absent»` - every `ops` element is a `pipeCommit` declaration. An element carrying another kind, or no readable `__action`, is not a compose commitment and nothing downstream can route it";
    };
    # THE CONTROL, same instrument same run: a well-formed commitment element registers clean. Without it
    # the three arms above are satisfiable by a validator that refuses every `ops` field it is handed.
    test-a10-commitment-element-registers-clean = {
      expr = registers [ { __action = "pipeCommit"; } ];
      expected = null;
    };
  };
}
