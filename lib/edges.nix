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
in
{
  inherit
    preRegisteredStrata
    reservedNames
    frameworkStrataInserts
    compile
    ;
}
