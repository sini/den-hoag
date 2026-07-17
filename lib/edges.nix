# The edge-kind registry (`den.edges.<kind>`, spec §2.2): the ONE registry describing every typed-edge
# kind — its structural stratum, its product typing, its algebraic discipline. den-hoag pre-registers the
# framework vocabulary; a user registers beside it. This module only DESCRIBES kinds (Law A1: one mapAttrs
# + validation, no algorithm); rewiring emission onto the substrate is a later step. The kind label a
# described kind carries is the typed-edge `K` component — an un-labeled edge (gen-edge's default) needs no
# registry row, so the pre-den vocabulary is untouched. See REFERENCE.md.
{ prelude }:
let
  # The framework-pre-registered kinds and their strata (spec §2.2): contains/include/kindOf are
  # structural; member/reach/reach-suppress resolution (selector-driven membership targets a later
  # stratum per §2.3, and literal declared membership rides the same kind harmlessly); nest/defer are
  # OUTPUT — a stratum the framework itself registers through the den.strata dense-insertion mechanism
  # after `demand` (the seed stays the shipped four; the framework dogfoods the extension).
  preRegisteredStrata = {
    contains = "structural";
    include = "structural";
    kindOf = "structural";
    member = "resolution";
    reach = "resolution";
    reach-suppress = "resolution";
    nest = "output";
    defer = "output";
  };
  reservedNames = builtins.attrNames preRegisteredStrata;

  # The strata the registry itself requires: `output` (nest/defer) enters the compiled order through the
  # SAME `den.strata.insert` machinery the user surface uses — dense-inserted after `demand`.
  frameworkStrataInserts = {
    output = {
      after = "demand";
    };
  };

  # A registry entry's canonical fields (spec §2.2). `data` is the per-kind edge-data schema; `requires`/
  # `produces` are the product typing (relation/derived kinds; unused by nest, whose typing derives from
  # its endpoint registries); `discipline` names the algebraic laws; `inverse` enables reverse queries;
  # `closure` is legal ONLY under a join-semilattice discipline (validated by the disciplines registry).
  entryOf =
    name: raw:
    let
      e = {
        data = raw.data or null;
        requires = raw.requires or null;
        produces = raw.produces or null;
        discipline = raw.discipline or null;
        inverse = raw.inverse or null;
        closure = raw.closure or false;
        stratum = raw.stratum or preRegisteredStrata.${name} or "resolution";
      };
    in
    # closure is a capability gated on an algebraic law: a closure kind without a declared discipline has
    # no laws to validate it (the disciplines registry owns that check). Abort NAMED rather than admit an
    # unlawful closure.
    if e.closure && e.discipline == null then
      throw "den.edges: kind '${name}' declares closure = true with no discipline — closure requires a declared discipline; discipline laws are validated by the disciplines registry"
    else
      e;

  # `compile { kinds; strataOrder }` → the validated compiled kind table (a `mapAttrs` + validation fold,
  # mirroring concern-classes' compile shape). Pre-registered kinds seed the table; a user kind merges
  # beside them. Re-registering a framework kind name aborts NAMED; a `stratum` outside the compiled order
  # aborts NAMED.
  compile =
    {
      kinds ? { },
      strataOrder,
    }:
    let
      strataSet = prelude.genAttrs strataOrder (_: true);
      # user kinds may not shadow the framework vocabulary — a reserved-name re-registration aborts.
      reservedOffenders = builtins.filter (n: builtins.elem n reservedNames) (builtins.attrNames kinds);
      # the full registration set: pre-registered framework rows (their strata) UNION the user rows.
      allRaw =
        prelude.genAttrs reservedNames (n: {
          stratum = preRegisteredStrata.${n};
        })
        // kinds;
      compiled = prelude.mapAttrs entryOf allRaw;
      # every entry's stratum must name a stratum in the compiled order.
      stratumOffenders = builtins.filter (n: !(strataSet ? ${compiled.${n}.stratum})) (
        builtins.attrNames compiled
      );
    in
    if reservedOffenders != [ ] then
      throw "den.edges: kind '${builtins.head reservedOffenders}' is framework-reserved"
    else if stratumOffenders != [ ] then
      throw "den.edges: kind '${builtins.head stratumOffenders}' names unknown stratum '${
        compiled.${builtins.head stratumOffenders}.stratum
      }' (not in the compiled order)"
    else
      compiled;

  # ── den.overrides: the pre-identity-freeze match/rewrite tier (spec §2.2) ──
  # Framework-emitted NEW-substrate edge INTENTS (`{ kind; from; to; data ? {}; }`) pass through the
  # override list BEFORE their edgeId is computed. An override is `{ match; rewrite; }`:
  #   • `match` — an attrset of PRE-HASH coordinates `{ kind ?; from ?; to ?; data ? { <field> = v; } }`.
  #     Every STATED coordinate must EQUAL the edge's (kind/from/to by whole value; `data` per-field);
  #     an absent coordinate is a wildcard. Matchers are STRUCTURAL DATA ONLY — no function-valued
  #     matchers (consistent with the fingerprint law; a selector-language upgrade is a later step).
  #   • `rewrite` — an attrset data-patch shallow-merged into `data` (`//`), or `null` = SUPPRESS the
  #     edge entirely (it contributes nothing downstream).
  # SINGLE-STEP: one pass over the list per edge, FIRST match wins, the rewritten edge is NEVER
  # re-matched (a rewrite that would satisfy a later entry's match does not re-fire).
  matchCoords = [
    "kind"
    "from"
    "to"
    "data"
  ];
  matchesEdge =
    match: edge:
    builtins.all (
      coord:
      if coord == "data" then
        builtins.all (f: (edge.data.${f} or null) == match.data.${f}) (builtins.attrNames match.data)
      else
        match.${coord} == (edge.${coord} or null)
    ) (builtins.attrNames match);
  applyOverrides =
    {
      overrides ? [ ],
      edges,
    }:
    let
      # definition-time totality: a match coordinate outside the closed set aborts NAMED.
      badCoordsOf = o: builtins.filter (c: !(builtins.elem c matchCoords)) (builtins.attrNames o.match);
      malformed = builtins.concatMap badCoordsOf overrides;
      # first-match scan (no prelude findFirst — an inline recursive scan): returns the rewritten edge,
      # or `null` to SUPPRESS, or the unchanged edge if nothing matches. Never re-matches a rewrite.
      overrideEdge =
        edge: os:
        if os == [ ] then
          edge
        else
          let
            o = builtins.head os;
          in
          if matchesEdge o.match edge then
            (if o.rewrite == null then null else edge // { data = (edge.data or { }) // o.rewrite; })
          else
            overrideEdge edge (builtins.tail os);
    in
    if malformed != [ ] then
      throw "den.overrides: match coordinate '${builtins.head malformed}' is not one of ${builtins.toJSON matchCoords}"
    else
      builtins.filter (e: e != null) (map (e: overrideEdge e overrides) edges);
in
{
  inherit
    preRegisteredStrata
    reservedNames
    frameworkStrataInserts
    compile
    applyOverrides
    ;
}
