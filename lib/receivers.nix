# The receives registry (`den.kinds.<outerKind>.receives.<slot>`, spec §4.2) — the graft-site rule as
# DATA on the outer kind. A receives row NAMES how an inner entity mounts into an outer one: its `at`
# placement (the paramPoint-first path), the product it `consumes` (from which its MODE is derived — F1's
# canonical machine form), its `arity`/`multiplicity`, and the `render`/`provide`/`adapt`/`identity`/`shape`
# hooks. This is the Bazel-provider reading once more: a slot is a typed consumer, and `consumes` names the
# product face it accepts. This task is DECLARATION + VALIDATION; the dispatch EXECUTION (the slot ≻ class
# lookup as a visible query over `kindOf include*`) is the mode-execution work. See REFERENCE.md.
#
# THE KIND-INCLUDE RELATION IS BORN HERE (Néron et al. 2015 name resolution — an include edge in the scope
# graph): `den.kinds.<kind>.includes` is a list of KIND NAMES — the receiver-inheritance relation BETWEEN
# KINDS (kind B including kind A inherits ALL of A's receives rows) the dispatch query walks upward for
# free. It sits on the KIND ENTRY (a sibling of `receives`), never on a receives row — inheritance is a
# kind→kind relation, and the dispatch lowers one include-set per kind. It is the receives-registry's OWN
# relation — NOT v1 schema `.includes` (whose entries were aspect-content includes lifted to per-entity
# policies, targeting aspects), and NOT `ent.meta.parent` (which is CONTAINMENT). No present-day carrier
# exists; this registry introduces it.
#
# NO EFFECT RUNTIME: `compile` is a nested `mapAttrs` + a validation fold — field defaults + product/kind/
# render checks, no algorithm (Law A1). An `at`/`provide`/`adapt`/`identity` value is a FUNCTION: a registry
# holds functions freely — the fingerprint law (identity.nix) bans functions from EDGE DATA only, never
# from a registry entry.
{
  prelude,
  productsLib,
}:
let
  # `arity` domain (spec §4.2): `many` (the default) or `singular`. The singular live-edge enforcement (two
  # predicate-differing edges into one singular mount both firing = a throw) is EXECUTED by the mode-execution
  # work, at BOTH definition-time and wiring — here the domain is validated, the enforcement is a later step.
  arities = [
    "many"
    "singular"
  ];
  # `multiplicity` domain (spec §4.2): `error` (the default) or `multi`.
  multiplicities = [
    "error"
    "multi"
  ];
  aritySet = prelude.genAttrs arities (_: true);
  multiplicitySet = prelude.genAttrs multiplicities (_: true);

  # A receives row's canonical fields (spec §4.2). THE §2.1 HOOK-SCOPING COROLLARY (the row contract): `at`
  # receives STRUCTURAL handles only (the paramPoint + the inner's structural face) — never resolved graph
  # state; `identity`/`provide`/`adapt` results are LAZY (the S-hashing law — a produced value never enters
  # the structural fill, only the producing node's structural reference does). `render` names a registered
  # render and is legal ONLY on an artifact-mode row (checked below — render is the artifact eval); `shape`
  # is `{ exclude; absorb }`. `mode` is NOT a field — it is DERIVED from `consumes` (F1) and surfaced as
  # `row.mode`; a user `mode` field is a definition error.
  rowOf =
    productsTable: renders: outerKind: slot: raw:
    let
      # F1 AS A CHECKED LAW: mode derives from consumes; a user-declared `mode` field is forbidden.
      hasMode = raw ? mode;
      # `consumes` passes the products-table gate (unregistered / non-nestable / literal ArtifactRef all
      # throw THERE, named — the pure fn reused from the products registry, never re-implemented).
      consumes = productsLib.checkConsumes productsTable raw.consumes;
      mode = productsLib.modeOf productsTable consumes;
      arity = raw.arity or "many";
      multiplicity = raw.multiplicity or "error";
      render = raw.render or null;
    in
    if hasMode then
      throw "den.kinds: receives rows derive mode from consumes — remove the mode field (${outerKind}.receives.${slot})"
    # `includes` is receiver inheritance BETWEEN KINDS — it lives on the kind entry (den.kinds.<kind>), not on
    # a receives row. A row-level `includes` is the exact kind/row confusion the kind-entry validation guards
    # against; reject it NAMED (the same posture as the F1 mode-field throw).
    else if raw ? includes then
      throw "den.kinds: 'includes' lives on den.kinds.${outerKind} (receiver inheritance between kinds), not on a receives row — move it up (${outerKind}.receives.${slot})"
    else if !(raw ? at) then
      throw "den.kinds: receives row '${outerKind}.receives.${slot}' declares no at — the placement `point: inner: [ …path ]` is required"
    else if !(raw ? consumes) then
      throw "den.kinds: receives row '${outerKind}.receives.${slot}' declares no consumes — the product face is required"
    else if !(aritySet ? ${arity}) then
      throw "den.kinds: receives row '${outerKind}.receives.${slot}' declares arity '${arity}' — one of ${builtins.toJSON arities}"
    else if !(multiplicitySet ? ${multiplicity}) then
      throw "den.kinds: receives row '${outerKind}.receives.${slot}' declares multiplicity '${multiplicity}' — one of ${builtins.toJSON multiplicities}"
    else if render != null && !(renders ? ${render}) then
      throw "den.kinds: receives row '${outerKind}.receives.${slot}' names unregistered render '${render}'"
    else if render != null && mode != "artifact" then
      throw "den.kinds: '${outerKind}.receives.${slot}' declares render '${render}' but consumes '${consumes}' is ${mode}-mode — render applies to artifact-mode consumption only"
    else
      {
        inherit (raw) at;
        inherit
          consumes
          mode
          arity
          multiplicity
          render
          ;
        provide = raw.provide or null;
        adapt = raw.adapt or null;
        identity = raw.identity or null;
        shape = raw.shape or null;
      };

  # `compile { rows; knownKinds; products; renders }` → the validated compiled receives table, keyed
  # `<outerKind>.receives.<slot>` (a nested `mapAttrs` + validation). `rows` is the fleet's `den.kinds`
  # config; `knownKinds` the registered kind names (an outer kind or an `includes` name outside the set
  # throws); `products` the COMPILED products table (§4.1, for the mode derivation + consumes gate);
  # `renders` the COMPILED render rows (§4.3, for the `render` name check). Duplicate slot rows are
  # impossible by attrset construction (the same posture as the conversions ruling). Invoked per-fleet (the
  # renders rows compile inside the mkDen closure), following the render read-through's placement.
  compile =
    {
      rows ? { },
      knownKinds ? [ ],
      products ? { },
      renders ? { },
    }:
    let
      productsTable = products;
      knownKindSet = prelude.genAttrs knownKinds (_: true);
      # each outer kind must be a registered kind; its `receives` bucket is the slot rows.
      unknownOuter = builtins.filter (k: !(knownKindSet ? ${k})) (builtins.attrNames rows);
      # each entry's `includes` (the kind-level receiver-inheritance relation) names known kinds; an unknown
      # include target throws NAMED at the entry that declares it.
      entryOf =
        outerKind: entry:
        let
          includes = entry.includes or [ ];
          badIncludes = builtins.filter (k: !(knownKindSet ? ${k})) includes;
        in
        if badIncludes != [ ] then
          throw "den.kinds: den.kinds.${outerKind}.includes names unknown kind '${builtins.head badIncludes}'"
        else
          entry
          // {
            inherit includes;
            receives = prelude.mapAttrs (rowOf productsTable renders outerKind) (entry.receives or { });
          };
    in
    if unknownOuter != [ ] then
      throw "den.kinds: receives table on unknown outer kind '${builtins.head unknownOuter}' (not a registered kind)"
    else
      prelude.mapAttrs entryOf rows;
in
{
  inherit compile;
}
