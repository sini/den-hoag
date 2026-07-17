# The edge-kind registry (`den.edges.<kind>`, spec §2.2) + the pre-identity-freeze override tier (§2.4)
# + the edge-assembly pipeline (§2.1). The registry DESCRIBES every typed-edge kind — its structural
# stratum, product typing, algebraic discipline; den-hoag pre-registers the framework vocabulary and a
# user registers beside it. `assembleEdges` runs SYNTHETIC edge intents through overrides → two-level
# identity → fill-graph acyclicity → gen-edge records stamped with `kind`. Every algorithm delegates to a
# named lib (Law A1: mapAttrs + validation for the registry; the identity module for the hashes; the
# override fold for the tier; gen-edge's `edge` for the record). See REFERENCE.md.
{
  prelude,
  identity,
  edge,
}:
let
  # The framework-pre-registered kinds and their strata (spec §2.2): contains/include/kindOf are
  # structural; member/reach/reach-suppress resolution (selector-driven membership targets a later
  # stratum per §2.3, and literal declared membership rides the same kind harmlessly); nest/defer are
  # OUTPUT — a stratum the framework itself registers through the den.strata dense-insertion mechanism
  # after `demand` (the seed stays the shipped four; the framework dogfoods the extension). `demand` is
  # the demand-stratum edge kind demand's `toEdges` stamps — the first live labeled kind (its records
  # cite this registry row).
  preRegisteredStrata = {
    contains = "structural";
    include = "structural";
    kindOf = "structural";
    member = "resolution";
    reach = "resolution";
    reach-suppress = "resolution";
    nest = "output";
    defer = "output";
    demand = "demand";
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

  # ── den.overrides: the pre-identity-freeze match/rewrite tier (spec §2.4) ──
  # Framework-emitted NEW-substrate edge INTENTS (`{ kind; from; to; data ? {}; }`) pass through the
  # override list BEFORE their edgeId is computed. An override is `{ match; rewrite; }`:
  #   • `match` — an attrset of PRE-HASH coordinates `{ kind ?; from ?; to ?; data ? { <field> = v; } }`.
  #     Every STATED coordinate must EQUAL the edge's (kind/from/to by whole value; `data` per-field);
  #     an absent coordinate is a wildcard. Matchers are STRUCTURAL DATA ONLY — no function-valued
  #     matchers (consistent with the fingerprint law; a selector-language upgrade is a later step).
  #     A `null` field VALUE in `match.data` matches both an explicitly-null and an absent edge field —
  #     there is no "explicitly null only" matcher in v1 (the null≡absent conflation is deliberate).
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

  # ── assembleEdges: override → two-level identity → fill-graph acyclicity → stamped record (§2.1) ──
  # SYNTHETIC-ONLY in this step: no live producer routes through here yet (a live producer arrives with
  # later spec steps). An intent is `{ kind; from = { entityId; class; s ? {}; }; to = <same>; data ? {} }`.
  # Order (the reviewer-ratified §2.4 rider): overrides match the RAW intent (pre-normalization — "pre-hash
  # coordinates" are the as-declared coordinates), THEN identities are computed on the surviving intents.
  #
  # data schema enforcement arrives with live producers — see REFERENCE.md

  # every string leaf of a structural fill (the producer-id references recorded IN S, §2.1).
  stringLeaves =
    v:
    if builtins.isString v then
      [ v ]
    else if builtins.isAttrs v then
      prelude.concatMap stringLeaves (builtins.attrValues v)
    else if builtins.isList v then
      prelude.concatMap stringLeaves v
    else
      [ ];

  assembleEdges =
    {
      kinds,
      overrides ? [ ],
      intents,
    }:
    let
      # unknown-kind guard (definition-time, named): every intent's kind must be a registered edge kind.
      unknownKinds = builtins.filter (i: !(kinds ? ${i.kind})) intents;
      # the override tier runs on the RAW intents; identities are computed on the survivors.
      survivors = applyOverrides {
        inherit overrides;
        edges = intents;
      };
      # per side: the content coordinate (assemblyId) and the placement (instanceId over canonical S).
      sideIdentity =
        side:
        let
          aid = identity.assemblyId {
            inherit (side) entityId class;
          };
        in
        {
          entityId = side.entityId;
          instanceId = identity.instanceId {
            assemblyId = aid;
            s = side.s or { };
          };
          s = side.s or { };
        };
      resolved = map (
        i:
        let
          from = sideIdentity i.from;
          to = sideIdentity i.to;
        in
        {
          inherit from to;
          record = edge.edge {
            # SYNTHETIC record: the intent's data is the value source; the target root is keyed by the
            # `to` instanceId (the placement). A live producer's source/target arms arrive with later
            # spec steps — here the record exists to carry the STAMPED kind + the frozen (T,P,S,M,K) key.
            source = edge.sources.value (i.data or { });
            target = edge.targets.root {
              root = to.instanceId;
              class = i.to.class;
            };
            kind = i.kind;
            annotations = {
              edgeId = identity.edgeId {
                inherit (i) kind;
                fromInstanceId = from.instanceId;
                toInstanceId = to.instanceId;
                dataFingerprint = identity.dataFingerprint (i.data or { });
              };
            };
          };
        }
      ) survivors;
      # The fill-reference graph (§2.1: "which producer-ids appear in whose S"), declared ACYCLIC. Nodes
      # are PER INSTANCE, keyed by instanceId — the instanceId is computable pre-check (S is literal data
      # in this vocabulary; it never contains the node's own instanceId, so there is no hash regress). The
      # check runs over the declared nominal reference structure per instance — the well-foundedness of
      # identity computation. Entity-sugar refs (an entityId string leaf in S) resolve ONLY when the entity
      # has exactly one instance in the assembly; a literal instanceId string leaf resolves directly (the
      # spec's own reference vocabulary). Checked ONCE per assembly.
      sides = prelude.concatMap (r: [
        r.from
        r.to
      ]) resolved;
      instanceIdSet = prelude.genAttrs (map (s: s.instanceId) sides) (_: true);
      # entityId -> the instanceIds it has in this assembly (an entity may fan out to several instances).
      entityInstances = prelude.foldl' (
        acc: s:
        acc
        // {
          ${s.entityId} = prelude.unique ((acc.${s.entityId} or [ ]) ++ [ s.instanceId ]);
        }
      ) { } sides;
      # resolve one S string leaf to a referenced instanceId, or `null` if it names nothing in the
      # assembly. A literal instanceId is a direct ref; an entityId is INSTANCE-DISCRIMINATING sugar —
      # it resolves iff the entity has exactly ONE instance here, else it is ambiguous and aborts NAMED
      # (resolving it to ALL the entity's instances would re-derive the entity quotient — the very
      # false-positive this keying removes).
      resolveRef =
        leaf:
        if instanceIdSet ? ${leaf} then
          leaf
        else if entityInstances ? ${leaf} then
          (
            let
              is = entityInstances.${leaf};
            in
            if builtins.length is == 1 then
              builtins.head is
            else
              throw "den.edges: assembleEdges structural-fill reference to entity '${leaf}' is ambiguous — it has ${toString (builtins.length is)} instances in this assembly; reference an instanceId"
          )
        else
          null;
      refsOf = side: builtins.filter (r: r != null) (map resolveRef (stringLeaves side.s));
      fillGraph = prelude.foldl' (
        acc: s:
        acc
        // {
          ${s.instanceId} = prelude.unique ((acc.${s.instanceId} or [ ]) ++ refsOf s);
        }
      ) { } sides;
    in
    if unknownKinds != [ ] then
      throw "den.edges: assembleEdges intent names unknown kind '${(builtins.head unknownKinds).kind}' (not in the registry)"
    else
      # checkFillAcyclic runs once per assembly; a cycle aborts NAMED (identity module). `seq` forces the
      # check before the records are handed back, so a cyclic assembly aborts rather than emitting.
      builtins.seq (identity.checkFillAcyclic fillGraph) (map (r: r.record) resolved);
in
{
  inherit
    preRegisteredStrata
    reservedNames
    frameworkStrataInserts
    compile
    applyOverrides
    assembleEdges
    ;
}
