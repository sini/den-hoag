# den.productions — the resolution-facet production surface (spec §5, Phase 5a). A production
# `<name> = { stratum; from; emit; discipline; mode; readsAttrs; compute }` is a REGISTRATION + CONTRACT +
# LAWS-GATING surface — NOT a generic query+fold DSL. It SUPPLIES its own PASSTHROUGH `compute` (self: id:
# value); the surface does NOT reconstruct a fold from `from`/`discipline`. `from` is the DECLARED SOURCE
# CONTRACT (a list of `{ kind ∈ {query,pool}; stratum ? null; }` sources naming the strata/graphs the compute
# reads) — it DRIVES the L2 gate + documents the contract, it is NOT executed. `readsAttrs` is EXPLICITLY
# declared (the compute-internal `self.get` reads), NOT derived from `from`. This file holds the DEFINITION-
# TIME vocabulary + laws validation (`productionMessage`, a value-detector) and the compile-to-equation
# (`compile`, the P5b lowering taxonomy — `{ equations; claimEdges }`).
#
# THE P5b LOWERING TAXONOMY (spec §5 ★REVISION). `emit ∈ { attr, edges, nodes }`:
#   attr                    → `resolve.attr` (the exact synthesized-attr shape resolved-settings emits).
#   edges, from = ∅          → off-trace EDB leaf claim edge FACTS (no equation kind) into the claim pool.
#   edges, from = own fields → `resolve.nta` (Vogt spawn: reads its OWN decl, emits sub-edges).
#   nodes                   → TWO equations: an attr-gather (reads the claim pool) + an `nta` spawn (L5-guarded).
# `emit = cascade`/unknown is REJECTED NAMED (it constructs compute, breaking the passthrough posture —
# settings/C8 only); `mode = fixpoint` is REJECTED NAMED (a later phase). `from` kinds ∈ { query, pool,
# reverse-query }. The rejection is AT REGISTRATION — an EXPLICIT boundary, not a silent throw-on-force.
#
# THE P3 LAWS. L2 (the load-bearing one): each declared `from` SOURCE must read a stratum STRICTLY BELOW the
# emit `stratum` (`strataScope.strataLt` over the compiled order; an absent from-stratum compares below every
# present one — a source that names no stratum is L2-clean). ★ L2 gates the `from`-SOURCES ONLY — NEVER
# `readsAttrs`: a production legitimately reads a SAME-stratum attr (a resolution-stratum production reading
# `resolved-aspects`, A9-legit per the P3 positional schedule's same-stratum positive read), so a readsAttrs-
# wide gate would false-reject. L1: an attr production supplies its own compute, so its relation reads take
# the production's stratum ceiling by declaration (the shipped mkDerived path) — no new L1 work here.
#
# NO EFFECT RUNTIME: `productionMessage` is a validation fold + `compile` is one `mapAttrs` (Law A1; the thin
# sibling of concern-derived's `derivedFieldMessage` + `mkDerived`). The validator is a VALUE (`null` = clean,
# else the first NAMED message) so the NAMED contract is CI-testable — Nix's `tryEval` cannot capture a
# throw's text. See REFERENCE.md.
{
  prelude,
  strataScope,
  resolve,
}:
let
  inherit (strataScope) strataLt;

  # the L5 bounded-NTA registration law (§8 law 5, Vogt 1989) — wired into registration for `emit = nodes`
  # (the value-invention boundary). Imported here (it needs only `strataScope`) so `productionMessage` can
  # gate a node-spawning production's four bounded-NTA clauses without a new call-site arg.
  inherit (import ./production-guard.nix { inherit strataScope; }) boundedNtaMessage;

  # the Phase-5b vocabulary (the closed sets a production field may name; anything else is rejected). `emit`
  # is now a SET — `attr` (P5a, resolve.attr), `edges` (a claim-edge intent for from=∅, else an nta spawn),
  # `nodes` (a bounded-NTA gather+spawn). `cascade`/unknown stays OUT (it constructs compute, breaking the
  # passthrough posture — settings/C8 only). `mode` stays single-valued `all` (fixpoint is a later phase).
  # `from` source kinds admit `reverse-query` (the later provider tasks' reverse gather) beside query/pool.
  supportedEmit = {
    attr = true;
    edges = true;
    nodes = true;
  };
  supportedMode = "all";
  supportedFromKinds = {
    query = true;
    pool = true;
    reverse-query = true;
  };

  # the raw-field render for a message (a non-string field prints `<none>` rather than crashing the message).
  strOf = v: if builtins.isString v then v else "<none>";

  # edbStubSelf — the THROW-ON-READ `self` a leaf claim's constant `compute` is applied against (both the
  # registration-time LIST-shape guard and the claimEdgesOf expansion). A leaf claim is pure EDB (extensional,
  # from = ∅, readsAttrs = []); it must NOT read the schedule. Reading `self.get` proves impurity and aborts
  # NAMED, so the EDB-purity law is enforced by construction, not by convention.
  edbStubSelf = {
    get =
      _id: _attr:
      throw "den.productions: an emit=edges CONSTANT leaf claim is pure EDB (from=∅, readsAttrs=[]) — its `compute` must not read `self` (§7 off-trace, from=∅ EDB law)";
  };

  # productionMessage — the DEFINITION-TIME validator as a VALUE (`null` = clean, else the first NAMED
  # message), so the NAMED contract is CI-testable (the derivedFieldMessage / boundedNtaMessage posture). It
  # checks each production's vocabulary (emit/mode/from-kind — the Phase-5b boundary), its `discipline`
  # membership, its `stratum` membership, and the P3 L2 from-source gate, plus the required-field presence
  # (`readsAttrs`/`compute`, an uncatchable attr-miss the moment `compile` forces them otherwise). Guards are
  # an ordered chain — vocabulary first (the explicit lower-only boundary), then discipline/stratum
  # membership, then the L2 gate (which reads the now-validated `stratum`), then field presence LAST.
  productionMessage =
    {
      strataOrder,
      disciplineNames,
    }:
    productions:
    let
      disciplineSet = prelude.genAttrs disciplineNames (_: true);
      checkOne =
        name: prod:
        let
          emit = prod.emit or null;
          mode = prod.mode or null;
          stratum = prod.stratum or null;
          from = prod.from or [ ];
          discipline = prod.discipline or null;
          fromKindOffenders = builtins.filter (s: !(supportedFromKinds ? ${s.kind or "<none>"})) from;
          # (L2) a `from` source whose read-stratum is NOT strictly below the emit stratum — the source would
          # draw from its own or a later layer (`!(s ≺ stratum)` = `stratum ≼ s`). An absent from-stratum
          # (null) compares below every present one, so a source naming no stratum is L2-clean.
          belowOffenders = builtins.filter (s: !(strataLt strataOrder (s.stratum or null) stratum)) from;
          # (L5) the bounded-NTA registration law for `emit = nodes` — the four §8-law-5 clauses over the
          # spawn shape (mode = all, from strictly-below, never self-reads the spawned keyspace, content
          # identity). Inert (null) for emit ≠ nodes; the guard reads `.name` for its message locus.
          ntaMessage = boundedNtaMessage strataOrder (prod // { inherit name; });
        in
        if builtins.match ".*__spawn" name != null then
          "den.productions: '${name}' uses the reserved '__spawn' suffix — it is synthesized as the emit = nodes spawn-equation key (§5), so a declared '__spawn' name would clobber it"
        else if !(supportedEmit ? ${strOf emit}) then
          "den.productions: '${name}' emit = '${strOf emit}' not supported — constructs compute, breaks passthrough (settings/C8 only)"
        else if mode != supportedMode then
          "den.productions: '${name}' mode = '${strOf mode}' not supported in Phase 5a (Phase 5b) — only mode = all"
        else if fromKindOffenders != [ ] then
          "den.productions: '${name}' from source kind = '${
            strOf ((builtins.head fromKindOffenders).kind or null)
          }' not supported (§5) — only query | pool | reverse-query"
        else if discipline != null && !(disciplineSet ? ${discipline}) then
          "den.productions: '${name}' discipline '${discipline}' is not registered in den.disciplines (§5)"
        else if !(builtins.isString stratum) || !(builtins.elem stratum strataOrder) then
          "den.productions: '${name}' names unknown stratum '${strOf stratum}' — not in the compiled strata order (§2.3)"
        else if belowOffenders != [ ] then
          "den.productions: '${name}' from source reads stratum '${
            strOf ((builtins.head belowOffenders).stratum or null)
          }' not strictly below its own stratum '${stratum}' — a production reads strata strictly below its emit stratum (§2.3 L2)"
        else if ntaMessage != null then
          ntaMessage
        else if emit == "nodes" && !(prod ? spawnNode) then
          # (L5) an emit = nodes production is the two-equation split: the `compute` is the attr-GATHER
          # (reads the below-stratum claim pool, groupBy dedupKey), and `spawnNode` is the CONTENT-ADDRESSED
          # spawn-builder the `${name}__spawn` nta applies to the gather output (gather → the spawned decl,
          # keyed by a content hash of the dedupKey — the Vogt 1989 finiteness witness). A missing spawnNode
          # would be an uncatchable `prod.spawnNode` attr-miss inside `lowerOne`, so it is caught here NAMED.
          "den.productions: '${name}' emit = nodes declares no `spawnNode` — a node-spawning production supplies a content-addressed spawn-builder `spawnNode = gather: <spawned decl>` the `${name}__spawn` nta applies to its gather (§5, §8 law 5, Vogt 1989)"
        else if !(prod ? readsAttrs) then
          "den.productions: '${name}' declares no `readsAttrs` — the compute-internal `self.get` reads are explicitly declared (§5)"
        else if !(prod ? compute) then
          "den.productions: '${name}' declares no `compute` — a production supplies its own passthrough `compute = self: id: value` (§5)"
        else if emit == "edges" && from == [ ] && !(builtins.isList (prod.compute edbStubSelf null)) then
          # the emit = edges CONSTANT (from = ∅) EDB leaf-claim shape law: its `compute` is a CONSTANT returning
          # the ground edge FACTS as a LIST of endpoint records. Forcing it here (against edbStubSelf) is free —
          # a leaf claim is pure EDB, so it reads no self, and the NAMED value keeps the shape rejection testable
          # AT REGISTRATION (the file's contract) rather than a cryptic length/index throw deep in claimEdgesOf.
          "den.productions: '${name}' emit=edges CONSTANT (from=∅) `compute` must return a LIST of endpoint records {from;to;data?} (§5 EDB leaf claim)"
        else
          null;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne productions);
    in
    if offenders == [ ] then null else builtins.head offenders;

  # attrEquation — the P5a synthesized attr (the exact shape resolved-settings emits). PASSTHROUGH: the
  # production's `compute` (self: id: value) IS the attr's compute — the surface reconstructs nothing.
  attrEquation =
    name: prod:
    resolve.attr {
      inherit name;
      kind = "synthesized";
      inherit (prod) stratum readsAttrs compute;
    };

  # claimEdgesOf — the off-trace EDB leaf claim edge facts for an `emit = edges` CONSTANT production (§7 off-
  # trace, from = ∅ EDB law, edge-uniform). A leaf claim (connect/secret/database/…) SUPPLIES its ground facts:
  # its constant `compute` returns a LIST of endpoint records `{ from; to; data ? {}; kind ? name; stratum ?
  # prod.stratum }` (the EDB — extensional, not derived), applied against `edbStubSelf` + a null id (EDB ignores
  # both; the LIST shape is validated at registration by `productionMessage`, so this expansion trusts it). Each
  # fact EXPANDS into one pool edge `{ id = "claim:<name>:<i>"; kind; from = <real source>; to = <real target>;
  # data; stratum }`, off-trace in the `den.relationEdges` pool (never on the materialization trace).
  #
  # THE COMPOSITE DESUGAR (strataChain composite-above-subclaims). A leaf claim omits per-fact `kind`/`stratum`,
  # so each fact defaults to the production's own name/stratum (the homogeneous leaf EDB, unchanged). A COMPOSITE
  # claim (a `route` fronting a host) instead RETURNS its SUB-CLAIM facts, each tagged with its OWN `kind` +
  # `stratum` (a `secret` fact at the secret stratum + a `connect` fact at the connect stratum) — the composite's
  # constant `compute` is a pure COMPILE-TIME fold (Vogt 1989 finiteness realized statically: the spawn tree is
  # finite + a content-function of the own decl; §G — NOT a resolve.nta, since the claim pool is materialized
  # before the resolve schedule so a resolve-time spawn would never join the static pool this transpose reads).
  # So ONE composite production emits HETEROGENEOUS sub-claim edges at strata STRICTLY BELOW its own — the
  # composite desugars away, only the sub-claim kinds/strata land in the pool.
  #
  # `from = ∅` is LOAD-BEARING: a pure EDB constant means cyclic connect data (arr→prowlarr AND prowlarr→arr) is
  # TWO independent facts at ONE acyclic stratum — a cycle in who-connects-whom is NOT a stratum cycle. It is
  # appended to the relation-edge pool, so `transpose`/`node.query`/the relation accessors see it exactly like a
  # `den.relations` desugar edge.
  claimEdgesOf =
    name: prod:
    prelude.imap0 (i: fact: {
      id = "claim:${name}:${toString i}";
      kind = fact.kind or name;
      inherit (fact) from to;
      data = fact.data or { };
      stratum = fact.stratum or prod.stratum;
    }) (prod.compute edbStubSelf null);

  # lowerOne — the corrected P5b lowering taxonomy for one guard-validated production (spec §5 ★REVISION):
  #   attr                    → one `resolve.attr` (P5a, unchanged).
  #   edges, from = ∅          → off-trace EDB leaf claim edge FACTS (no equation) into the claim pool.
  #   edges, from = own fields → `resolve.nta` (Vogt spawn: reads its OWN decl, readsAttrs = [], emits sub-edges).
  #   nodes                   → TWO equations (the two-equation split): an attr-gather `${name}` (`prod.compute`
  #                             reads the claim pool via `readsAttrs`, groups by dedupKey) plus an `nta` spawn
  #                             `${name}__spawn` that reads EXCLUSIVELY the gather on its own node and hands it to
  #                             the content-addressed `prod.spawnNode`. The structural closure (spawnNode's
  #                             `gather → decl` signature) keeps the spawn from closing over the pool; the
  #                             gather→spawn ordering is demand-guaranteed, not schedule-verified (see the branch).
  # Each yields `{ equations; claimEdges; claimKinds }` (the shape `compile` folds). Passthrough is preserved:
  # edge-intent supplies data, nta supplies spawn-from-own-decl, attr supplies compute. The leaf-claim branch
  # ALSO emits `claimKinds` — the SINGLE source of the claim-kind → stratum index the §9 claim-accessor reverse-
  # read scopes by (so the leaf-claim predicate is tested in ONE place, here), unioned over each expanded fact's
  # EFFECTIVE kind→stratum so a COMPOSITE's heterogeneous sub-claim kinds register at THEIR strata, not the
  # composite name (a homogeneous leaf unions to the single `{ <name> = { stratum }; }` — the homogeneous leaf).
  lowerOne =
    name: prod:
    let
      emit = prod.emit or "attr";
      from = prod.from or [ ];
    in
    if emit == "edges" && from == [ ] then
      let
        edges = claimEdgesOf name prod;
      in
      {
        equations = { };
        claimEdges = edges;
        # the claim-kind → `{ stratum }` index the §9 claim-accessor reverse-read scopes by — the DECLARED-
        # REGISTRY enumeration the L4 negation consumes via `.rel` (distinguishing out-of-scope from absent),
        # so it must be stable under ZERO facts (a declared leaf keeps its present-returning-empty `.rel` gate,
        # never an attr-miss). A HOMOGENEOUS leaf (every fact's kind = name, or zero facts) seeds its OWN decl —
        # `all` over empty edges = true, so a fact-less leaf still registers `{ ${name} = { stratum }; }` (the
        # homogeneous leaf is byte-identical). A COMPOSITE (strataChain composite-above-subclaims) desugars into
        # HETEROGENEOUS sub-claim facts (some fact.kind ≠ name) — `all` false, so the composite's OWN name is NOT
        # seeded (it stays desugared away); only its sub-claim kinds register at THEIR strata (strictly below the
        # composite's own), becoming reverse-readable.
        claimKinds =
          (if builtins.all (e: e.kind == name) edges then { ${name} = { inherit (prod) stratum; }; } else { })
          // builtins.listToAttrs (
            map (e: {
              name = e.kind;
              value = {
                inherit (e) stratum;
              };
            }) edges
          );
      }
    else if emit == "edges" then
      {
        equations.${name} = resolve.nta {
          inherit name;
          spawn = prod.compute;
        };
        claimEdges = [ ];
        claimKinds = { };
      }
    else if emit == "nodes" then
      # THE emit = nodes TWO-EQUATION SHAPE (spec §5 ★REVISION). `resolve.nta` hardcodes readsAttrs = [ ]
      # + stratum = "structural" (equation.nix), so an nta CANNOT itself read the below-stratum claim pool —
      # the read must be SPLIT into a schedulable attr the nta then consumes:
      #   `${name}`        = the attr-GATHER: `prod.compute` (self: id: reads the below-stratum claim pool via
      #                      readsAttrs = ["claim-accessor"], groups the claimants by dedupKey → this node's
      #                      { dedupKey; aggregate-of-all-sharers }). A resolution-stratum attr, scheduled.
      #   `${name}__spawn` = the nta-SPAWN: reads EXCLUSIVELY the gather on its OWN node (`self.get id ${name}`)
      #                      and hands it to `prod.spawnNode` — the CONTENT-ADDRESSED spawn-builder (gather →
      #                      the spawned decl, keyed by a content hash of the dedupKey). Content-addressing is
      #                      the L5 finiteness witness: N claimants of one dedupKey all spawn the SAME node id
      #                      ⇒ collapse to ONE shared node (§8 law 5, Vogt 1989 bounded-NTA).
      #
      # THE STRUCTURAL CLOSURE (the spawn reads ONLY the gather). `spawnNode`'s signature is `gather → decl` — it
      # receives ONLY the gather VALUE, never `self`/`id`/the pool. So the spawn STRUCTURALLY cannot re-introduce
      # a schedule-invisible below-stratum read inside the nta: the framework-authored `spawn` closure is the
      # SOLE `self`-holder and reads exactly `${name}`. The gather → spawn ordering is DEMAND-guaranteed (the
      # spawn forces the gather; the gather is pure + acyclic — it never reads the spawn), NOT schedule-verified:
      # the nta's hardcoded readsAttrs = [ ] + stratum = "structural" make the gather→spawn edge statically
      # invisible, so the schedule cannot order it. The full static fix = `resolve.nta` accepting stratum +
      # readsAttrs (a DEFERRED gen-resolve change); until then the demand-order is the honest residual.
      {
        equations = {
          ${name} = attrEquation name prod;
          "${name}__spawn" = resolve.nta {
            name = "${name}__spawn";
            spawn = self: id: prod.spawnNode (self.get id name);
          };
        };
        claimEdges = [ ];
        claimKinds = { };
      }
    else
      {
        equations.${name} = attrEquation name prod;
        claimEdges = [ ];
        claimKinds = { };
      };

  # compile — lower every production into `{ equations; claimEdges; claimKinds }`: `equations` is the attrset
  # merged into the ONE equations map (attr / nta / two-equation), `claimEdges` is the off-trace intent LIST
  # appended to the relation-edge pool, and `claimKinds` is the leaf-claim → `{ stratum }` index the §9
  # claim-accessor reverse-read scopes by (the SINGLE source of the leaf-claim predicate). Assumes a guard-
  # validated table (the mkDerived posture — the field guard runs at the wiring); folding forces the (guard-
  # seq'd) table's spine, so the guard fires whenever compile is built. Empty productions ⇒
  # `{ equations = { }; claimEdges = [ ]; claimKinds = { }; }` ⇒ byte-identical to the pre-P5b state.
  compile =
    {
      productions ? { },
    }:
    let
      lowered = prelude.mapAttrsToList lowerOne productions;
    in
    {
      equations = builtins.foldl' (acc: l: acc // l.equations) { } lowered;
      claimEdges = builtins.concatMap (l: l.claimEdges) lowered;
      claimKinds = builtins.foldl' (acc: l: acc // l.claimKinds) { } lowered;
    };
in
{
  inherit
    productionMessage
    compile
    ;
}
