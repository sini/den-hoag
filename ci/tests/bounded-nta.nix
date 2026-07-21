# The BOUNDED-NTA suite (§8 law 5, L5). A production that spawns nodes (`emit = "nodes"`, a content-addressed
# node-inventing production — Vogt 1989 bounded NTA, the admissible non-invention form of the chase) is the
# value-invention boundary. It is bounded — finiteness is a THEOREM, not a runtime check — ONLY under four
# registration clauses (spec §8 law 5):
#   1. mode = all         — a spawned-node production is a single ordered pass, not a within-stratum fixpoint.
#   2. from strictly-below — every `from` source reads STRICTLY BELOW the emit stratum (a well-founded pool).
#   3. never self-reads    — the production may not read the keyspace it spawns (non-monotone / unbounded).
#   4. content identity     — node identity is a content-function of the producing input (finiteness witness:
#                            finite EDB ⇒ finite pool ⇒ finite image).
# There is NO `den.productions.<name>` user surface yet (Phase 5 lands it + its behavioral consumer, dedup
# bundles). L5 lands the registration LAW now, as a STANDALONE guard over a production-shaped record, exercised
# SYNTHETICALLY — no fleet declares `emit = nodes`, so the guard is inert on every current corpus. Phase-5's
# `den.productions` compile calls `boundedNtaGuard` at registration (threading the compiled strata order, as the
# edge-kind compile threads `strataOrder`). See REFERENCE.md §5.
{
  denHoag,
  ...
}:
let
  guard = denHoag.internal.productionGuard;

  throws = e: !(builtins.tryEval (builtins.deepSeq e true)).success;

  # a synthetic strata order (the dedup witness §10: a `dedup` stratum strictly above the `route` cascade that
  # feeds it). The guard reads relative strata position via the shared `strataLt` primitive (§2.3).
  strataOrder = [
    "structural"
    "connect"
    "route"
    "resolution"
    "dedup"
  ];

  # the CONFORMANT dedup production (§10 witness 2): emit = nodes<shared-name>, mode = all, reads the `route`
  # cascade STRICTLY BELOW its own `dedup` stratum, never reads its own `shared-name` keyspace, content identity.
  conformant = {
    name = "shared-secret";
    stratum = "dedup";
    emit = "nodes";
    keyspace = "shared-name";
    mode = "all";
    from = [
      {
        stratum = "route";
        reads = "connect";
      }
    ];
    identity = "content";
  };

  # (clause 1) mode = fixpoint on a spawned-node production — a value-invention loop is not well-founded.
  fixpointNodes = conformant // {
    mode = "fixpoint";
  };
  # (clause 2) a `from` source reads AT its own stratum (`dedup`, not strictly below) — the pool is not well-founded.
  notBelowNodes = conformant // {
    from = [
      {
        stratum = "dedup";
        reads = "connect";
      }
    ];
  };
  # (clause 3) a `from` source reads the very `shared-name` keyspace it spawns — non-monotone / unbounded.
  selfReadNodes = conformant // {
    from = [
      {
        stratum = "route";
        reads = "shared-name";
      }
    ];
  };
  # (clause 4) node identity is not a content-function of the producing input.
  opaqueIdNodes = conformant // {
    identity = "opaque";
  };
  # (clause 3, null-keyspace witness) an otherwise-conformant spawn with keyspace = null AND a source that reads
  # null — the `keyspace != null` guard means two absent keyspaces are NOT a self-read, so clause 3 must NOT
  # false-positive. Registers clean (a spawn with an unnamed keyspace is the Phase-5 parser's presence concern,
  # not law 5's four clauses).
  nullKeyspaceNodes = conformant // {
    keyspace = null;
    from = [
      {
        stratum = "route";
        reads = null;
      }
    ];
  };

  # (inertness) a NON-nodes production (emit = attr) deliberately violating EVERY clause — the guard is a no-op,
  # since the bounded-NTA law fires ONLY for `emit = nodes`. This is the corpus witness: no shipped production
  # spawns nodes, so the guard NEVER fires.
  inertAttr = {
    name = "not-a-spawn";
    stratum = "dedup";
    emit = "attr";
    keyspace = "shared-name";
    mode = "fixpoint";
    from = [
      {
        stratum = "dedup";
        reads = "shared-name";
      }
    ];
    identity = "opaque";
  };

  # msgOf — the message validator called DIRECTLY (the closureMessage / derivedFieldMessage posture): each
  # violation's NAMED text is asserted in isolation, since Nix's `tryEval` cannot capture a real throw's text.
  msgOf = guard.boundedNtaMessage strataOrder;
  matches = re: record: builtins.match re (msgOf record) != null;
in
{
  flake.tests.bounded-nta = {
    # ── a conformant emit = nodes production registers clean (message null, guard is the identity) ──
    test-bounded-nta-conformant-clean = {
      expr = msgOf conformant;
      expected = null;
    };
    test-bounded-nta-conformant-registers = {
      expr = (guard.boundedNtaGuard strataOrder conformant).emit;
      expected = "nodes";
    };
    test-bounded-nta-conformant-no-throw = {
      expr = throws (guard.boundedNtaGuard strataOrder conformant);
      expected = false;
    };

    # ── clause 1: mode ≠ all rejects NAMED ──
    test-bounded-nta-fixpoint-throws = {
      expr = throws (guard.boundedNtaGuard strataOrder fixpointNodes);
      expected = true;
    };
    test-bounded-nta-fixpoint-named = {
      expr = matches ".*emit = nodes requires mode = all.*" fixpointNodes;
      expected = true;
    };

    # ── clause 2: a `from` source not strictly below the emit stratum rejects NAMED ──
    test-bounded-nta-not-below-throws = {
      expr = throws (guard.boundedNtaGuard strataOrder notBelowNodes);
      expected = true;
    };
    test-bounded-nta-not-below-named = {
      expr = matches ".*not strictly below.*" notBelowNodes;
      expected = true;
    };

    # ── clause 3: reading the spawned keyspace rejects NAMED ──
    test-bounded-nta-self-read-throws = {
      expr = throws (guard.boundedNtaGuard strataOrder selfReadNodes);
      expected = true;
    };
    test-bounded-nta-self-read-named = {
      expr = matches ".*reads the keyspace.*it spawns.*" selfReadNodes;
      expected = true;
    };

    # ── clause 4: non-content-function identity rejects NAMED ──
    test-bounded-nta-opaque-id-throws = {
      expr = throws (guard.boundedNtaGuard strataOrder opaqueIdNodes);
      expected = true;
    };
    test-bounded-nta-opaque-id-named = {
      expr = matches ".*content-function.*" opaqueIdNodes;
      expected = true;
    };

    # ── clause 3 null-keyspace: a null keyspace + a null-reading source is NOT a self-read (registers clean) ──
    test-bounded-nta-null-keyspace-clean = {
      expr = msgOf nullKeyspaceNodes;
      expected = null;
    };

    # ── inertness: an emit ≠ nodes production is untouched, even when it violates every clause ──
    test-bounded-nta-non-nodes-clean = {
      expr = msgOf inertAttr;
      expected = null;
    };
    test-bounded-nta-non-nodes-no-throw = {
      expr = throws (guard.boundedNtaGuard strataOrder inertAttr);
      expected = false;
    };
  };
}
