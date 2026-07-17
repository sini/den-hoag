# The receives registry (`den.kinds.<outerKind>.receives.<slot>`, spec §4.2) — the graft-site rule as
# DATA on the outer kind. A receives row NAMES how an inner entity mounts into an outer one: its `at`
# placement (the paramPoint-first path), the product it `consumes` (from which its MODE is derived — F1's
# canonical machine form), its `arity`/`multiplicity`, and the `render`/`provide`/`adapt`/`identity`/`shape`
# hooks. This is the Bazel-provider reading once more: a slot is a typed consumer, and `consumes` names the
# product face it accepts. Registry compile + validation live here alongside the slot ≻ class DISPATCH
# (`resolveReceiver`, a visible query over `kindOf include*`); the mode EXECUTION on live nest edges is a
# later step. See REFERENCE.md.
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
  graph,
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

  # ── THE DISPATCH (spec §4.2 ruling F4): slot ≻ class as a gen-graph VISIBLE query ─────────────────────
  # `resolveReceiver { compiledKinds; outerKind; slot; class }` executes the graft-site lookup: the outer
  # kind's own rows first, inherited rows via kind-includes with NEAREST-WINS, the containment SLOT kind
  # taking precedence over the inner's CLASS kind, an equal-precedence tie a definition-time throw (unless
  # the winning row declares `multiplicity = "multi"`). The walk is a REAL gen-graph query over the
  # kind-include graph — no hand-rolled closure. Néron et al. 2015: name resolution as a reachability query
  # over a scope graph, the visible declarations = the nearest un-shadowed ones.
  #
  # `resolveKey outerKind key` finds the nearest kind(s) carrying `receives.<key>`, upward over `include*`:
  #   • kindGraph lowers the receiver-inheritance relation: one include-set per KIND (the kind-include field).
  #   • `where` gates a kind as an ANSWER only when it carries the key — LOAD-BEARING: without it the
  #     depth-0 outer kind (nullable `include*`) always answers, row or not, and nothing inherits.
  #   • `groupBy = _: key` forces the CONSTANT single group so every carrying kind competes for nearest-wins;
  #     the default per-node grouping would put each kind in its own group and never shadow anything.
  #   • nearest-wins is the DEFAULT endOfPath = -1 prefix-wins word order (a proper prefix beats its
  #     extensions) — the single-label alphabet makes label ranking inert, so order.labels stays unset.
  # `res.visible` = the nearest carrying kind(s) (equal-rank ties included = the ambiguity set); depth-0
  # self answers first when it carries the row.
  resolveKey =
    compiledKinds: outerKind: key:
    let
      kindGraph = graph.labeledFrom {
        include = k: compiledKinds.${k}.includes or [ ];
      };
      res = graph.query {
        graph = kindGraph;
        from = outerKind;
        follow = graph.regex.parse "include*";
        where = k: (compiledKinds.${k}.receives or { }) ? ${key};
        mode = "visible";
        groupBy = _: key;
      };
      # DIAMOND DEDUP: per-path enumeration answers a diamond-reachable kind ONCE PER PATH with equal-rank
      # words; dedup the visible answers by NODE before the equal-precedence check, else a legal diamond
      # throws a false ambiguity. First-occurrence dedup preserves the visible (nearest-first) node order.
      dedupNodes = builtins.foldl' (
        acc: a: if builtins.elem a.node acc then acc else acc ++ [ a.node ]
      ) [ ] res.visible;
    in
    dedupNodes;

  # `resolveReceiver { compiledKinds; outerKind; slot; class }` — the slot ≻ class two-phase resolution.
  # Resolve the `receives.<slot>` rows first; on EMPTY, fall back to `receives.<class>` rows. A tie of two
  # DISTINCT carrying kinds at the winning depth (after the node-dedup) throws NAMED, unless ALL tied rows
  # declare `multiplicity = "multi"` (then they coexist — all returned, visible-ordered); a tied set that
  # DISAGREES on multiplicity is its own named error (the opt-out must be unanimous, else the outcome would
  # hinge on visible-order position). An unknown outer kind throws; no rows anywhere returns `null` — a
  # LEGAL no-receiver result (mode execution decides its meaning). Pure + total.
  resolveReceiver =
    {
      compiledKinds,
      outerKind,
      slot,
      class,
    }:
    if !(compiledKinds ? ${outerKind}) then
      throw "den.kinds: resolveReceiver on unknown outer kind '${outerKind}'"
    else
      let
        rowFor = key: kind: compiledKinds.${kind}.receives.${key};
        # slot phase, then class phase on empty (the F4 fallback).
        slotKinds = resolveKey compiledKinds outerKind slot;
        classKinds = resolveKey compiledKinds outerKind class;
        phase =
          if slotKinds != [ ] then
            {
              key = slot;
              kinds = slotKinds;
            }
          else
            {
              key = class;
              kinds = classKinds;
            };
        winners = map (rowFor phase.key) phase.kinds;
        # the multi opt-out must be UNANIMOUS across the tied set — otherwise the outcome would depend on
        # visible-order position (whichever tied row sorts first). ALL tied rows declaring `multi` ⇒ they
        # coexist (all returned, visible-ordered); ANY declaring `error` (the default) ⇒ ambiguity; a set
        # that DISAGREES (some multi, some error) is its own named error (never silently resolved either way).
        multiFlags = map (w: (w.multiplicity or "error") == "multi") winners;
        allMulti = builtins.all (x: x) multiFlags;
        anyMulti = builtins.any (x: x) multiFlags;
      in
      if phase.kinds == [ ] then
        null
      else if builtins.length phase.kinds == 1 then
        builtins.head winners
      else if allMulti then
        winners
      else if anyMulti then
        # some-but-not-all (allMulti already excluded above)
        throw
          "den.kinds: equal-precedence receivers disagree on multiplicity: ${builtins.toJSON phase.kinds} — all tied rows must declare multiplicity = \"multi\" to coexist"
      else
        throw "den.kinds: ambiguous receiver for '${outerKind}.receives.${phase.key}' — kinds ${builtins.toJSON phase.kinds} carry it at equal precedence; disambiguate or declare multiplicity = \"multi\"";
in
{
  inherit compile resolveReceiver;
}
