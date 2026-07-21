# production-guard — the bounded-NTA registration law for a node-spawning production (spec §8 law 5, L5).
# `emit = "nodes"` is the VALUE-INVENTION boundary (Fagin–Kolaitis–Miller–Popa 2005 weak acyclicity / the chase;
# undecidable in general). It is bounded — finiteness is a THEOREM, not a runtime check — ONLY in Vogt's 1989
# bounded-NTA form, which den's content-addressed edge identity (S1 `edgeId`) already satisfies. This guard
# enforces the four registration clauses that make the spawned pool finite by construction:
#   1. mode = all          — a spawned-node production is a single ordered pass, not a within-stratum fixpoint.
#   2. from strictly-below  — every `from` source reads STRICTLY BELOW the emit stratum (the pool is well-founded).
#   3. never self-reads     — the production may not read the keyspace it spawns (non-monotone / unbounded).
#   4. content identity     — node identity is a content-function of the producing input (the finiteness witness:
#                             finite EDB ⇒ finite pool ⇒ finite image).
# There is NO `den.productions.<name>` user surface yet — the node-spawning surface + its behavioral consumer
# (dedup bundles) land in Phase 5. This is a STANDALONE guard over a production-shaped record (§4 vocabulary:
# `emit ∈ {edges,attr,nodes}`, `mode ∈ {all,fixpoint}`, `from` = sources at strata, `keyspace` = the spawned
# pool, `identity` = the node-id derivation). Phase-5's `den.productions` compile calls `boundedNtaGuard` at
# registration (threading the compiled strata order, exactly as the edge-kind compile threads `strataOrder`).
# `emit != "nodes"` ⇒ the guard is a NO-OP (inert on every current corpus — no shipped production spawns nodes).
{
  strataScope,
}:
let
  # the §2.3 strictly-below primitive, shared with the relation accessors and the derive compute (an absent
  # stratum compares below every present one — the total `indexOf` comparison).
  inherit (strataScope) strataLt;

  # boundedNtaMessage — the registration validator as a VALUE (`null` = lawful, else the NAMED message), so the
  # NAMED contract is CI-testable (Nix's `tryEval` cannot capture a throw's text — the closureMessage /
  # derivedFieldMessage posture). Guards are an ordered chain, applied ONLY when `emit == "nodes"`:
  #   mode-gate → from-strictly-below → self-keyspace → content-identity. `strataOrder` is the compiled linear
  # strata order (for the §2.3 comparison); `production` is the production-shaped record.
  boundedNtaMessage =
    strataOrder: production:
    let
      emit = production.emit or null;
      mode = production.mode or null;
      stratum = production.stratum or null;
      keyspace = production.keyspace or null;
      from = production.from or [ ];
      identity = production.identity or null;
      name = production.name or "<production>";
      idStr = if builtins.isString identity then identity else "<none>";
      # (clause 2) a `from` source whose read-stratum is NOT strictly below the emit stratum — the spawned pool
      # would draw from its own or a later layer, so it is not well-founded (`!(s ≺ stratum)` = `stratum ≼ s`).
      belowOffenders = builtins.filter (src: !(strataLt strataOrder (src.stratum or null) stratum)) from;
      # (clause 3) a `from` source that reads the very keyspace this production spawns — a self-read makes the
      # pool depend on its own output (non-monotone / unbounded). Guarded on `keyspace != null` (a spawn always
      # names a keyspace; the guard never conflates two absent keyspaces).
      selfReadOffenders = builtins.filter (src: keyspace != null && (src.reads or null) == keyspace) from;
    in
    if emit != "nodes" then
      null
    else if mode != "all" then
      "den.productions: '${name}' emit = nodes requires mode = all — a spawned-node production is a single ordered pass (bounded-NTA), not a within-stratum fixpoint (§8 law 5, Vogt 1989)"
    else if belowOffenders != [ ] then
      "den.productions: '${name}' emit = nodes reads a `from` source at stratum '${
        (builtins.head belowOffenders).stratum or "<none>"
      }' not strictly below its own stratum '${
        if builtins.isString stratum then stratum else "<none>"
      }' — a spawned pool must read strictly below, else it is not well-founded (§8 law 5, bounded-NTA)"
    else if selfReadOffenders != [ ] then
      "den.productions: '${name}' emit = nodes reads the keyspace '${keyspace}' it spawns — a spawned-node production may not read its own spawned keyspace (non-monotone / unbounded, §8 law 5, bounded-NTA)"
    else if identity != "content" then
      "den.productions: '${name}' emit = nodes identity is not a content-function of the producing input (identity = '${idStr}') — bounded-NTA finiteness requires content-addressed node identity (§8 law 5, Vogt 1989)"
    else
      null;

  # boundedNtaGuard — the throwing wrapper over boundedNtaMessage: aborts NAMED on the first violated clause,
  # else returns the production untouched (so a registration call site can `boundedNtaGuard strataOrder prod`
  # inline). Mirrors edges.nix's `closureGate` (message-value + seq-throw); `seq` forces the check before the
  # record is handed back.
  boundedNtaGuard =
    strataOrder: production:
    let
      m = boundedNtaMessage strataOrder production;
    in
    builtins.seq (if m != null then throw m else null) production;
in
{
  inherit
    boundedNtaMessage
    boundedNtaGuard
    ;
}
