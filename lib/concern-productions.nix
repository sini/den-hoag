# den.productions — the resolution-facet production surface (spec §5, Phase 5a). A production
# `<name> = { stratum; from; emit; discipline; mode; readsAttrs; compute }` is a REGISTRATION + CONTRACT +
# LAWS-GATING surface — NOT a generic query+fold DSL. It SUPPLIES its own PASSTHROUGH `compute` (self: id:
# value); the surface does NOT reconstruct a fold from `from`/`discipline`. `from` is the DECLARED SOURCE
# CONTRACT (a list of `{ kind ∈ {query,pool}; stratum ? null; }` sources naming the strata/graphs the compute
# reads) — it DRIVES the L2 gate + documents the contract, it is NOT executed. `readsAttrs` is EXPLICITLY
# declared (the compute-internal `self.get` reads), NOT derived from `from`. This file holds the DEFINITION-
# TIME vocabulary + laws validation (`productionMessage`, a value-detector) and the compile-to-equation
# (`compile`, one `resolve.attr` per production — the exact synthesized-attr shape resolved-settings emits).
#
# LOWER-ONLY (Phase 5a): `emit = attr`, `mode = all`, `from` kinds ∈ { query, pool }, `discipline` ∈ the
# compiled registry. ANY other value (emit = edges/nodes, mode = fixpoint, an unknown from-source kind) is a
# NAMED "Phase 5a (Phase 5b)" rejection AT REGISTRATION — an EXPLICIT boundary, not a silent throw-on-force.
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

  # the Phase-5a LOWER-ONLY vocabulary (the closed sets a production field may name; anything else is a
  # Phase-5b rejection). `emit`/`mode` are single-valued; `from` source kinds are a set.
  supportedEmit = "attr";
  supportedMode = "all";
  supportedFromKinds = {
    query = true;
    pool = true;
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
        in
        if emit != supportedEmit then
          "den.productions: '${name}' emit = '${strOf emit}' not supported in Phase 5a (Phase 5b) — only emit = attr"
        else if mode != supportedMode then
          "den.productions: '${name}' mode = '${strOf mode}' not supported in Phase 5a (Phase 5b) — only mode = all"
        else if fromKindOffenders != [ ] then
          "den.productions: '${name}' from source kind = '${
            strOf ((builtins.head fromKindOffenders).kind or null)
          }' not supported in Phase 5a (Phase 5b) — only query | pool"
        else if discipline != null && !(disciplineSet ? ${discipline}) then
          "den.productions: '${name}' discipline '${discipline}' is not registered in den.disciplines (§5)"
        else if !(builtins.isString stratum) || !(builtins.elem stratum strataOrder) then
          "den.productions: '${name}' names unknown stratum '${strOf stratum}' — not in the compiled strata order (§2.3)"
        else if belowOffenders != [ ] then
          "den.productions: '${name}' from source reads stratum '${
            strOf ((builtins.head belowOffenders).stratum or null)
          }' not strictly below its own stratum '${stratum}' — a production reads strata strictly below its emit stratum (§2.3 L2)"
        else if !(prod ? readsAttrs) then
          "den.productions: '${name}' declares no `readsAttrs` — the compute-internal `self.get` reads are explicitly declared (§5)"
        else if !(prod ? compute) then
          "den.productions: '${name}' declares no `compute` — a production supplies its own passthrough `compute = self: id: value` (§5)"
        else
          null;
      offenders = builtins.filter (m: m != null) (prelude.mapAttrsToList checkOne productions);
    in
    if offenders == [ ] then null else builtins.head offenders;

  # compile — one `resolve.attr` per production (the exact synthesized-attr shape resolved-settings emits),
  # keyed by production name, ready to `//`-merge into the equations map. PASSTHROUGH: the production's
  # `compute` (self: id: value) IS the attr's compute — the surface reconstructs nothing. Assumes a guard-
  # validated table (the mkDerived posture — the field guard runs at the wiring, not inside the compute
  # engine); `mapAttrs` forces the (guard-seq'd) table's spine, so the guard fires whenever the equations
  # map is built. Empty productions ⇒ `{ }` ⇒ byte-identical to the pre-Phase-5a equation map.
  compile =
    {
      productions ? { },
    }:
    builtins.mapAttrs (
      name: prod:
      resolve.attr {
        inherit name;
        kind = "synthesized";
        inherit (prod) stratum readsAttrs compute;
      }
    ) productions;
in
{
  inherit
    productionMessage
    compile
    ;
}
