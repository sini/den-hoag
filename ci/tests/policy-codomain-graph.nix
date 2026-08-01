# THE DECLARED CODOMAINS AND THE SIGNED POLICY DEPENDENCY GRAPH.
#
# `emits` names the declaration KINDS a body may produce. Two of those kinds also create an EDGE in the
# policy dependency graph, and Lemma 1 (Apt, Blair & Walker 1988, "Stratified Programs", p. 97) is a
# condition on the WHOLE graph: a program is stratified iff no cycle contains a negative edge. So both
# edge families have to be known BEFORE the graph is decided, which is what the two refined codomains are:
#
#   `suppresses`  the NEGATIVE family — the named policy's gate consults, negatedly, the set this one
#                 contributed.
#   `binds`       the POSITIVE family — a containment binding is a dependency of every policy that
#                 destructures its key.
#
# ★ CHECKING THE NEGATIVE SUBGRAPH ALONE WOULD NOT BE LEMMA 1, and this suite's central row is the
# witness: with `P` suppressing `Q` and `P` reading a binding `Q` emits, the cycle is
# `Q --neg--> P --pos--> Q`. One of its two edges is POSITIVE, so a check ranging over the negative
# subgraph sees a single edge and no cycle at all.
#
# ★ AND THE PAIRED CONTROL IS NOT OPTIONAL. Condition 1 (p. 96) ADMITS same-stratum positive reads, so a
# purely POSITIVE cycle is a legal program that must be ACCEPTED. A guard rejecting it would be
# over-strict rather than safe, and over-strictness is indistinguishable from soundness on a suite that
# only ever asserts rejection.
{ denHoag, ... }:
let
  inherit (denHoag) sel;
  inherit (denHoag) declare;
  I = denHoag.internal;

  schema = {
    config.den.schema = {
      zone.parent = null;
      rack.parent = "zone";
      blade.parent = "rack";
    };
  };
  instances = {
    config.den = {
      zone.z1 = { };
      rack.r1 = { };
    };
  };

  # A containment emitter DECLARING the key it binds. Its `binds` is the producer side of a positive edge.
  binder = key: {
    selects = sel.attrs { type = "zone"; };
    emits = [ "member" ];
    binds = [ key ];
    fn =
      { zone, ... }@ctx:
      builtins.seq ctx [
        (declare.member {
          coords = {
            inherit zone;
            rack = {
              id_hash = "rack-r1";
              name = "r1";
            };
          };
          bindings.${key} = "v";
          containTo = "rack";
        })
      ];
  };

  # A suppressor that also READS a binding key. Its formals are the reader side of a positive edge and
  # its `suppresses` is the negative one, so a single record can close a cycle by itself. The formal is
  # written literally in each variant because a Nix function's formals cannot be computed — which is also
  # why the reader side of a positive edge is read off the gate rather than derived.
  suppressorReadingTok = target: at: {
    selects = at;
    emits = [ "suppress" ];
    suppresses = [ target ];
    fn =
      { tok, ... }:
      builtins.seq tok [ (declare.suppress { name = target; }) ];
  };
  suppressorReadingHost = target: at: {
    selects = at;
    emits = [ "suppress" ];
    suppresses = [ target ];
    fn =
      { host, ... }:
      builtins.seq host [ (declare.suppress { name = target; }) ];
  };

  mk =
    policies:
    (denHoag.mkDen [
      schema
      instances
      { config.den.policies = policies; }
    ]).den;
  registerOnly = policies: (mk policies).scopeRoots;

  # ── A3b: the cycle CLOSED THROUGH A BINDING EDGE. `drop-binder` suppresses `binder` and destructures
  #    `tok`, which `binder` declares in `binds`. Negative edge binder→drop-binder, positive edge
  #    drop-binder→binder: one cluster, one negative edge inside it. ─────────────────────────────────────
  bindingCycle = {
    binder = binder "tok";
    drop-binder = suppressorReadingTok "binder" (sel.attrs { type = "rack"; });
  };

  # ── A4b: the SAME shape with the two policies at kinds that can never meet at one node. `posOf` is a
  #    GLOBAL name test with no reachability scoping, so they merge into one cluster anyway and the
  #    program is rejected. This is the approximation's DIRECTION pinned as intended: it over-rejects,
  #    never over-admits, which is the safe side for a soundness guard. Scoping the edge would need a
  #    per-(policy, node) reachability relation that does not exist at registration. ────────────────────
  unmeetableCycle = {
    binder = binder "host";
    drop-binder = suppressorReadingHost "binder" (sel.attrs { type = "blade"; });
  };

  # ── A4: a purely POSITIVE cycle — each policy destructures the key the other declares in `binds`, and
  #    neither suppresses anything. Condition 1 admits it, so it must REGISTER CLEAN. ──────────────────
  positiveCycle = {
    p1 = {
      selects = sel.attrs { type = "zone"; };
      emits = [ "member" ];
      binds = [ "a" ];
      fn =
        { b, ... }:
        builtins.seq b [ ];
    };
    p2 = {
      selects = sel.attrs { type = "zone"; };
      emits = [ "member" ];
      binds = [ "b" ];
      fn =
        { a, ... }:
        builtins.seq a [ ];
    };
  };

  # ── A7: a body producing OUTSIDE its declared codomain. Registration is clean for both — the
  #    declarations are well-formed on their own — so the conflict can only surface at the emission. ────
  suppressOutOfCodomain = {
    rogue = {
      selects = sel.attrs { type = "rack"; };
      emits = [ "suppress" ];
      suppresses = [ "declared-target" ];
      fn = _ctx: [ (declare.suppress { name = "undeclared-target"; }) ];
    };
  };
  bindOutOfCodomain = {
    rogue = {
      selects = sel.attrs { type = "zone"; };
      emits = [ "member" ];
      binds = [ "declared" ];
      fn =
        { zone, ... }:
        [
          (declare.member {
            coords = {
              inherit zone;
              rack = {
                id_hash = "rack-r1";
                name = "r1";
              };
            };
            bindings.undeclared = "v";
            containTo = "rack";
          })
        ];
    };
  };
in
{
  flake.tests.policy-codomain-graph = {
    # ── REGISTRATION: each codomain is REQUIRED exactly when its kind is emitted. `policyMessage` returns
    #    its verdict as a VALUE (`null` = clean), so the message TEXT is asserted directly — Nix cannot
    #    recover a throw's text, which is why this validator returns rather than throws. ────────────────
    test-suppresses-required-when-suppress-emitted = {
      expr = I.policyMessage {
        a = {
          emits = [ "suppress" ];
          selects = sel.star;
          fn = _ctx: [ ];
        };
      };
      expected = "den.policies: `a` emits `suppress` but declares no `suppresses` - the suppression codomain is REQUIRED. `suppresses = [ ]` (an EMPTY HEAD) is a legal value; an omitted `suppresses` is not, because the stratification is decided from the DECLARED graph and a graph that can be extended by execution decides nothing";
    };
    test-binds-required-when-member-emitted = {
      expr = I.policyMessage {
        a = {
          emits = [ "member" ];
          selects = sel.star;
          fn = _ctx: [ ];
        };
      };
      expected = "den.policies: `a` emits `member` but declares no `binds` - the BINDING codomain is REQUIRED. A containment binding is a POSITIVE dependency of every policy that destructures it, and Apt-Blair-Walker Lemma 1 (p. 97) forbids a cycle containing a negative edge, not a cycle: the positive edges must be known before the check. `binds = [ ]` (a member that carries no bindings) is a legal value; an omitted `binds` is not";
    };

    # ── …and the EMPTY codomain is LEGAL, which is the same ruling `emits = [ ]` already carries one level
    #    up: an empty head is a rule that may fire and name nobody, not an absent declaration. ──────────
    test-empty-codomains-register-clean = {
      expr = I.policyMessage {
        a = {
          emits = [ "suppress" ];
          selects = sel.star;
          suppresses = [ ];
          fn = _ctx: [ ];
        };
        b = {
          emits = [ "member" ];
          selects = sel.star;
          binds = [ ];
          fn = _ctx: [ ];
        };
      };
      expected = null;
    };

    # ── SPURIOUS: a NON-EMPTY codomain on a policy with no head to create those edges names a dependency
    #    the rule cannot make. An EMPTY one names no dependency at all, so it is not spurious — the
    #    paired row above is what keeps this check from being a presence test wearing a value test's
    #    justification. ────────────────────────────────────────────────────────────────────────────────
    test-nonempty-codomain-without-its-head-is-spurious = {
      expr = I.policyMessage {
        a = {
          emits = [ "enrich" ];
          selects = sel.star;
          suppresses = [ "x" ];
          fn = _ctx: [ ];
        };
      };
      expected = "den.policies: `a` declares `suppresses` but does not emit `suppress` - a suppression codomain without a suppression head names a dependency the rule cannot create";
    };

    # ── LEMMA 1 OVER THE WHOLE GRAPH: the cycle whose second edge is POSITIVE. A check ranging over the
    #    negative subgraph alone sees one edge here and admits the program. ──────────────────────────────
    test-cycle-through-a-binding-edge-aborts = {
      expr = registerOnly bindingCycle;
      expectedError = {
        type = "ThrownError";
        msg = "has a cycle through the NEGATIVE edge contributed by";
      };
    };

    # ── THE APPROXIMATION'S DIRECTION, pinned rather than hidden: two policies that can never fire at the
    #    same node still merge, because the positive edge is a global NAME test. Over-rejection is the
    #    safe direction, and the abort prints the whole cluster so a false rejection is legible and is
    #    repaired by renaming a key or splitting a codomain. ────────────────────────────────────────────
    test-unmeetable-policies-still-merge-into-one-cluster = {
      expr = registerOnly unmeetableCycle;
      expectedError = {
        type = "ThrownError";
        msg = "the mutually-dependent cluster is";
      };
    };

    # ── THE PAIRED CONTROL: a purely POSITIVE cycle is LEGAL under condition 1 and must be accepted. A
    #    guard that rejected it would be over-strict, and this suite could not tell the difference
    #    without this row. ─────────────────────────────────────────────────────────────────────────────
    test-positive-cycle-is-admitted = {
      expr = I.policyMessage positiveCycle;
      expected = null;
    };
    test-positive-cycle-evaluates = {
      expr = (builtins.tryEval (builtins.deepSeq (registerOnly positiveCycle) true)).success;
      expected = true;
    };

    # ── THE FIRING-TIME HALF. Without it the registration check decides from a graph EXECUTION CAN STILL
    #    EXTEND, and the messages above become false: an edge a body introduces is an edge the check
    #    never saw. Both kinds ride the same map, in the arm that already computed the kind. ────────────
    test-suppress-outside-codomain-aborts-at-the-emission = {
      expr = (mk suppressOutOfCodomain).structural.eval.get "rack:r1" "suppressed-policies";
      expectedError = {
        type = "ThrownError";
        msg = "which is not in its declared `suppresses`";
      };
    };
    test-binding-outside-codomain-aborts-at-the-emission = {
      expr = (mk bindOutOfCodomain).membershipTuples;
      expectedError = {
        type = "ThrownError";
        msg = "which is not in its declared `binds`";
      };
    };
  };
}
