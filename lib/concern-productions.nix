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
#   edges, from = ∅          → a plain off-trace claim-edge INTENT (no equation kind) into the claim pool.
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
        else if !(prod ? readsAttrs) then
          "den.productions: '${name}' declares no `readsAttrs` — the compute-internal `self.get` reads are explicitly declared (§5)"
        else if !(prod ? compute) then
          "den.productions: '${name}' declares no `compute` — a production supplies its own passthrough `compute = self: id: value` (§5)"
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

  # claimEdgeOf — an off-trace claim-edge INTENT for an `emit = edges` CONSTANT production (from = ∅). It is
  # a plain edge fact (NO equation kind), shaped `{ id; kind; from; to; data; stratum }`: `to = "query"` (the
  # §7 off-trace projection target — the claim pool, never on the materialization trace), `data` (the
  # passthrough `compute` supplies the intent payload), `stratum` (the emit stratum, carried for the later
  # provider engine's §2.3 comparison). The provider engine refines the endpoints/kind. It is appended to the
  # relation-edge pool, so `transpose`/`node.query`/the relation accessors see it, off-trace, exactly like a
  # `den.relations` desugar edge.
  claimEdgeOf = name: prod: {
    id = "claim:${name}";
    kind = name;
    from = name;
    to = "query";
    data = prod.compute;
    stratum = prod.stratum;
  };

  # lowerOne — the corrected P5b lowering taxonomy for one guard-validated production (spec §5 ★REVISION):
  #   attr                    → one `resolve.attr` (P5a, unchanged).
  #   edges, from = ∅          → an off-trace claim-edge INTENT (no equation) into the claim pool.
  #   edges, from = own fields → `resolve.nta` (Vogt spawn: reads its OWN decl, readsAttrs = [], emits sub-edges).
  #   nodes                   → TWO equations: an attr-gather (reads the claim pool via `readsAttrs`) keyed by
  #                             the emitted name, plus an `nta` spawn (`<name>__spawn`). The gather+spawn wiring
  #                             (the spawn consuming the gather's inventory) is the claim engine's behavioral
  #                             concern (a later task); this lands the two schedulable equations + the L5 guard.
  # Each yields `{ equations; claimEdges }` (the shape `compile` folds). Passthrough is preserved: edge-intent
  # supplies data, nta supplies spawn-from-own-decl, attr supplies compute.
  lowerOne =
    name: prod:
    let
      emit = prod.emit or "attr";
      from = prod.from or [ ];
    in
    if emit == "edges" && from == [ ] then
      {
        equations = { };
        claimEdges = [ (claimEdgeOf name prod) ];
      }
    else if emit == "edges" then
      {
        equations.${name} = resolve.nta {
          inherit name;
          spawn = prod.compute;
        };
        claimEdges = [ ];
      }
    else if emit == "nodes" then
      {
        equations = {
          ${name} = attrEquation name prod;
          "${name}__spawn" = resolve.nta {
            name = "${name}__spawn";
            spawn = prod.compute;
          };
        };
        claimEdges = [ ];
      }
    else
      {
        equations.${name} = attrEquation name prod;
        claimEdges = [ ];
      };

  # compile — lower every production into `{ equations; claimEdges }`: `equations` is the attrset merged into
  # the ONE equations map (attr / nta / two-equation), `claimEdges` is the off-trace intent LIST appended to
  # the relation-edge pool. Assumes a guard-validated table (the mkDerived posture — the field guard runs at
  # the wiring); folding forces the (guard-seq'd) table's spine, so the guard fires whenever compile is built.
  # Empty productions ⇒ `{ equations = { }; claimEdges = [ ]; }` ⇒ byte-identical to the pre-P5b state.
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
    };
in
{
  inherit
    productionMessage
    compile
    ;
}
